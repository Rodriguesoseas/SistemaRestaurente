class MovimentacaoEstoque < ApplicationRecord
  include HistoricoImutavel
  ENTRADA = "entrada"
  SAIDA = "saida"
  TIPOS = [ ENTRADA, SAIDA ].freeze

  MOTIVOS_ENTRADA = %w[compra ajuste devolucao outros].freeze
  MOTIVOS_SAIDA = %w[consumo_interno perda ajuste outros].freeze
  MOTIVOS = (MOTIVOS_ENTRADA + MOTIVOS_SAIDA).uniq.freeze

  ROTULOS_MOTIVO = {
    "compra" => "Compra",
    "ajuste" => "Ajuste",
    "devolucao" => "Devolução",
    "consumo_interno" => "Consumo interno",
    "perda" => "Perda",
    "outros" => "Outros"
  }.freeze

  belongs_to :produto
  belongs_to :user

  around_create :atualizar_saldo_atomicamente
  validates :quantidade, decimal_seguro: { scale: 3 }

  validates :tipo, inclusion: { in: TIPOS }
  validates :quantidade, presence: true, numericality: { greater_than: 0 }
  validates :motivo, inclusion: { in: MOTIVOS }
  validates :ocorrido_em, presence: true
  validate :motivo_compativel_com_tipo
  validate :ocorrido_em_nao_futuro

  scope :entradas, -> { where(tipo: ENTRADA) }
  scope :saidas, -> { where(tipo: SAIDA) }
  scope :recentes, -> { order(ocorrido_em: :desc, id: :desc) }

  def entrada?
    tipo == ENTRADA
  end

  def saida?
    tipo == SAIDA
  end

  def motivo_rotulo
    ROTULOS_MOTIVO.fetch(motivo, motivo)
  end

  def self.motivos_para(tipo)
    tipo == SAIDA ? MOTIVOS_SAIDA : MOTIVOS_ENTRADA
  end

  def self.registrar!(produto:, user:, tipo:, quantidade:, motivo:, observacao: nil, ocorrido_em: Time.current)
    create!(produto: produto, user: user, tipo: tipo, quantidade: quantidade,
      motivo: motivo, observacao: observacao, ocorrido_em: ocorrido_em || Time.current)
  end

  private

  def atualizar_saldo_atomicamente
    produto.with_lock do
      saldo = produto.quantidade_atual + (saida? ? -quantidade : quantidade)
      if saldo.negative? || !produto.ativo?
        errors.add(:base, "Produto deve estar ativo e o saldo não pode ficar negativo.")
        raise ActiveRecord::RecordInvalid, self
      end
      produto.update!(quantidade_atual: saldo)
      yield
    end
  end

  def motivo_compativel_com_tipo
    return if motivo.blank? || tipo.blank?
    return if self.class.motivos_para(tipo).include?(motivo)

    errors.add(:motivo, "não pertence a este tipo de movimentação")
  end

  def ocorrido_em_nao_futuro
    return if ocorrido_em.blank?
    return if ocorrido_em <= Time.current

    errors.add(:ocorrido_em, "não pode ser no futuro")
  end
end
