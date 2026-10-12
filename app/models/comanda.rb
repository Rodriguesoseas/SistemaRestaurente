class Comanda < ApplicationRecord
  ABERTA = "aberta"
  FECHADA = "fechada"
  CANCELADA = "cancelada"
  STATUSES = [ ABERTA, FECHADA, CANCELADA ].freeze

  belongs_to :mesa
  belongs_to :abertura_user, class_name: "User"
  belongs_to :pagamento_user, class_name: "User", optional: true
  belongs_to :caixa
  has_many :item_comandas, dependent: :restrict_with_error
  has_one :movimentacao_financeira, dependent: nil

  before_create :abrir_com_bloqueio
  before_update :proteger_encerramento
  before_destroy :preservar_historico, prepend: true
  validates :valor_total, decimal_seguro: true

  validates :status, inclusion: { in: STATUSES }
  validates :aberta_em, presence: true
  validates :valor_total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :forma_pagamento, inclusion: { in: MovimentacaoFinanceira::FORMAS_EXPLICITAS }, allow_nil: true
  validate :caixa_aberto_para_abertura, on: :create
  validate :mesa_ativa_para_abertura, on: :create
  validate :apenas_uma_comanda_aberta_por_mesa, on: :create

  scope :abertas, -> { where(status: ABERTA) }
  scope :recentes, -> { order(aberta_em: :desc, id: :desc) }

  def aberta?
    status == ABERTA
  end

  def fechada?
    status == FECHADA
  end

  def total_calculado
    item_comandas.sum(:subtotal)
  end

  def recalcular_total!
    # Chamado pelas mutações de itens sob o mesmo lock usado pelo pagamento.
    # Usa update_column para evitar validações (comanda pode estar fechada).
    self.valor_total = total_calculado
    update_column(:valor_total, valor_total)
  end

  def com_bloqueio_itens
    # Para operações de itens: basta travar a comanda.
    # O produto será travado dentro do callback do ItemComanda.
    with_lock { yield }
  end

  def com_bloqueio_pagamento
    # Para pagamento: trava caixa e depois comanda (ordem fixa para evitar deadlock).
    caixa.with_lock do
      with_lock { yield }
    end
  end

  def pagar!(forma_pagamento:, usuario:)
    com_bloqueio_pagamento do
      unless aberta?
        errors.add(:base, "Esta comanda já foi encerrada.")
        raise ActiveRecord::RecordInvalid, self
      end
      unless caixa.aberto?
        errors.add(:base, "Abra o caixa antes de finalizar esta comanda.")
        raise ActiveRecord::RecordInvalid, self
      end
      recalcular_total!
      if valor_total <= 0
        errors.add(:base, "Comanda sem valor não pode ser finalizada como venda.")
        raise ActiveRecord::RecordInvalid, self
      end
      categoria_venda = CategoriaFinanceira.find_by!(tipo: CategoriaFinanceira::ENTRADA, nome: "Venda")
      movimentacao = MovimentacaoFinanceira.create!(
        caixa: caixa,
        user: usuario,
        categoria_financeira: categoria_venda,
        tipo: MovimentacaoFinanceira::ENTRADA,
        descricao: "Pagamento comanda — Mesa #{mesa.numero}",
        valor: valor_total,
        forma_pagamento: forma_pagamento,
        ocorrido_em: Time.current,
        comanda: self
      )
      update!(
        status: FECHADA,
        fechada_em: Time.current,
        pagamento_user: usuario,
        forma_pagamento: forma_pagamento
      )
      movimentacao
    end
  end

  private

  def abrir_com_bloqueio
    caixa.with_lock do
      mesa.with_lock do
        unless caixa.aberto? && mesa.ativo?
          errors.add(:base, "Caixa aberto e mesa ativa são obrigatórios para abrir comandas.")
          throw :abort
        end
      end
    end
  end

  def proteger_encerramento
    caixa.with_lock do
      atual = self.class.lock.find(id)
      unless atual.aberta? && caixa.aberto?
        errors.add(:base, "Comanda encerrada ou caixa fechado não pode ser alterado.")
        throw :abort
      end
      if fechada? && !MovimentacaoFinanceira.where(comanda_id: id, caixa_id: caixa_id, valor: valor_total).exists?
        errors.add(:base, "O encerramento exige o pagamento atômico da comanda.")
        throw :abort
      end
    end
  end

  def preservar_historico
    errors.add(:base, "Comandas históricas não podem ser excluídas.")
    throw :abort
  end

  def caixa_aberto_para_abertura
    return if caixa&.aberto?

    errors.add(:caixa, "precisa estar aberto para abrir comandas")
  end

  def mesa_ativa_para_abertura
    return if mesa&.ativo?

    errors.add(:mesa, "precisa estar ativa para abrir comandas")
  end

  def apenas_uma_comanda_aberta_por_mesa
    return if mesa.nil? || !aberta?
    return unless Comanda.where(mesa: mesa).abertas.exists?

    errors.add(:mesa, "já possui comanda aberta")
  end
end
