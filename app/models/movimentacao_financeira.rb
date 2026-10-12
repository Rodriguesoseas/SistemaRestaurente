class MovimentacaoFinanceira < ApplicationRecord
  include HistoricoImutavel
  ENTRADA = "entrada"
  SAIDA = "saida"
  TIPOS = [ ENTRADA, SAIDA ].freeze

  NAO_INFORMADA = "nao_informada"
  FORMAS_PAGAMENTO = %w[dinheiro pix debito credito outro nao_informada].freeze
  FORMAS_EXPLICITAS = (FORMAS_PAGAMENTO - [ NAO_INFORMADA ]).freeze
  DINHEIRO = "dinheiro"

  ROTULOS_FORMA_PAGAMENTO = {
    "dinheiro" => "Dinheiro",
    "pix" => "Pix",
    "debito" => "Débito",
    "credito" => "Crédito",
    "outro" => "Outro",
    "nao_informada" => "Não informada"
  }.freeze

  belongs_to :caixa
  belongs_to :user
  belongs_to :categoria_financeira
  belongs_to :comanda, optional: true

  before_create :registrar_com_caixa_bloqueado
  validates :valor, decimal_seguro: true

  validates :tipo, inclusion: { in: TIPOS }
  validates :descricao, presence: true
  validates :valor, presence: true, numericality: { greater_than: 0 }
  validates :forma_pagamento, inclusion: { in: FORMAS_PAGAMENTO }
  validates :ocorrido_em, presence: true
  validate :ocorrido_em_nao_futuro
  validates :comanda_id, uniqueness: true, allow_nil: true
  validate :forma_pagamento_obrigatoria_na_entrada
  validate :categoria_compativel_com_tipo
  validate :caixa_aberto_para_lancamento, on: :create
  validate :pagamento_de_comanda_e_entrada

  scope :entradas, -> { where(tipo: ENTRADA) }
  scope :saidas, -> { where(tipo: SAIDA) }
  scope :recentes, -> { order(ocorrido_em: :desc, id: :desc) }

  def entrada?
    tipo == ENTRADA
  end

  def saida?
    tipo == SAIDA
  end

  def forma_pagamento_rotulo
    ROTULOS_FORMA_PAGAMENTO.fetch(forma_pagamento, forma_pagamento)
  end

  private

  def registrar_com_caixa_bloqueado
    caixa.with_lock do
      unless caixa.aberto?
        errors.add(:caixa, "precisa estar aberto para registrar movimentações")
        throw :abort
      end
      if comanda && (comanda.caixa_id != caixa_id || categoria_financeira.nome != "Venda" || !entrada?)
        errors.add(:comanda, "deve pertencer ao mesmo caixa e originar uma Venda")
        throw :abort
      end
    end
  end

  def forma_pagamento_obrigatoria_na_entrada
    return unless entrada?
    return if FORMAS_EXPLICITAS.include?(forma_pagamento)

    errors.add(:forma_pagamento, "é obrigatória nas entradas")
  end

  def categoria_compativel_com_tipo
    return if categoria_financeira.nil? || tipo.blank?
    return if categoria_financeira.tipo == tipo

    errors.add(:categoria_financeira, "não pertence a este tipo de lançamento")
  end

  def caixa_aberto_para_lancamento
    return if caixa&.aberto?

    errors.add(:caixa, "precisa estar aberto para registrar movimentações")
  end

  def pagamento_de_comanda_e_entrada
    return if comanda.nil?
    return if entrada?

    errors.add(:comanda, "só pode originar entradas")
  end

  def ocorrido_em_nao_futuro
    return if ocorrido_em.blank?
    return if ocorrido_em <= Time.current

    errors.add(:ocorrido_em, "não pode ser no futuro")
  end
end
