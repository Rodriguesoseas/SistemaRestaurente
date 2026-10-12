class Caixa < ApplicationRecord
  ABERTO = "aberto"
  FECHADO = "fechado"
  STATUSES = [ ABERTO, FECHADO ].freeze

  belongs_to :user
  belongs_to :fechamento_user, class_name: "User", optional: true
  has_many :movimentacao_financeiras, dependent: :restrict_with_error
  has_many :comandas, dependent: nil

  before_update :atualizar_com_bloqueio
  before_destroy :preservar_historico, prepend: true
  validates :saldo_inicial, decimal_seguro: true
  validates :valor_contado, decimal_seguro: true, allow_nil: true

  validates :saldo_inicial, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :aberto_em, presence: true
  validate :apenas_um_caixa_aberto, on: :create
  validate :valor_contado_valido, if: :fechado?
  validate :nao_alterar_caixa_fechado, on: :update

  scope :aberto, -> { where(status: ABERTO) }
  scope :recentes, -> { order(aberto_em: :desc) }

  def self.atual
    aberto.first
  end

  def aberto?
    status == ABERTO
  end

  def fechado?
    status == FECHADO
  end

  def entradas
    movimentacao_financeiras.entradas.sum(:valor)
  end

  def saidas
    movimentacao_financeiras.saidas.sum(:valor)
  end

  def resultado
    entradas - saidas
  end

  def saldo_consolidado
    saldo_inicial + resultado
  end

  def dinheiro_esperado
    entradas_dinheiro = movimentacao_financeiras.entradas.where(forma_pagamento: MovimentacaoFinanceira::DINHEIRO).sum(:valor)
    saidas_dinheiro = movimentacao_financeiras.saidas.where(forma_pagamento: MovimentacaoFinanceira::DINHEIRO).sum(:valor)
    saldo_inicial + entradas_dinheiro - saidas_dinheiro
  end

  def totais_entradas_por_pagamento
    movimentacao_financeiras.entradas.group(:forma_pagamento).sum(:valor)
  end

  def comandas_pendentes
    comandas.abertas.includes(:mesa).order("mesas.numero")
  end

  private

  def atualizar_com_bloqueio
    atual = self.class.lock.find(id)
    if atual.fechado?
      errors.add(:base, "Caixa fechado não pode ser alterado.")
      throw :abort
    end
    if fechado?
      pendentes = atual.comandas_pendentes.to_a
      if pendentes.any?
        mesas = pendentes.map { |c| "Mesa #{c.mesa.numero}" }.join(", ")
        errors.add(:base, "Finalize as comandas pendentes antes de fechar o caixa: #{mesas}.")
        throw :abort
      end
      self.valor_esperado_dinheiro = atual.dinheiro_esperado
      self.diferenca = valor_contado - valor_esperado_dinheiro if valor_contado
    end
  end

  def preservar_historico
    errors.add(:base, "Caixas históricos não podem ser excluídos.")
    throw :abort
  end

  def apenas_um_caixa_aberto
    return unless aberto?
    return unless self.class.aberto.exists?

    errors.add(:base, "Já existe um caixa aberto. Feche-o antes de abrir outro.")
  end

  def valor_contado_valido
    if valor_contado.nil?
      errors.add(:valor_contado, "não pode ficar em branco")
    elsif valor_contado.negative?
      errors.add(:valor_contado, "não pode ser negativo")
    end
  end

  def nao_alterar_caixa_fechado
    return unless status_in_database == FECHADO

    errors.add(:base, "Caixa fechado não pode ser alterado.")
  end
end
