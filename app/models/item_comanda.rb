class ItemComanda < ApplicationRecord
  belongs_to :comanda
  belongs_to :produto

  before_validation :aplicar_snapshot_do_produto, on: :create
  before_validation :calcular_subtotal
  before_save :salvar_com_bloqueio
  before_destroy :destruir_com_bloqueio, prepend: true
  after_save :recalcular_total_da_comanda
  after_destroy :recalcular_total_da_comanda

  validates :quantidade, presence: true, numericality: { greater_than: 0 }
  validates :valor_unitario, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :produto_vendavel, on: :create
  validate :comanda_aberta_para_alteracao, on: [ :create, :update ]
  validate :snapshot_imutavel, on: :update
  validates :quantidade, decimal_seguro: { scale: 3 }
  validates :valor_unitario, :subtotal, decimal_seguro: true

  attr_accessor :preco_exibido, :confirmar_preco

  private

  def salvar_com_bloqueio
    comanda.com_bloqueio_itens do
      throw :abort unless operacao_permitida?

      restante = comanda.item_comandas.where.not(id: id).sum(:subtotal)
      if subtotal && restante + subtotal >= 100_000_000
        errors.add(:subtotal, "excede o limite de valor total da comanda")
        throw :abort
      end

      if new_record?
        produto.with_lock do
          produto_vendavel
          if preco_exibido.present? && confirmar_preco != "1"
            exibido = BigDecimal(preco_exibido.to_s, exception: false)
            errors.add(:base, "O preço mudou. Confirme o preço atual.") unless exibido == produto.preco_venda
          end
          throw :abort if errors.any?

          aplicar_snapshot_do_produto
          calcular_subtotal
          throw :abort unless valid?
        end
      end
    end
  end

  def destruir_com_bloqueio
    comanda.com_bloqueio_itens do
      throw :abort unless operacao_permitida?
    end
  end

  def operacao_permitida?
    return true if comanda.aberta? && comanda.caixa.aberto?

    errors.add(:comanda, "e o caixa precisam estar abertos para alterar itens")
    false
  end

  def snapshot_imutavel
    if (changes.keys & %w[produto_id comanda_id descricao valor_unitario]).any?
      errors.add(:base, "Produto, comanda, descrição e preço histórico não podem ser alterados.")
    end
  end

  def aplicar_snapshot_do_produto
    return if produto.nil?

    self.descricao = produto.nome
    self.valor_unitario = produto.preco_venda
  end

  def calcular_subtotal
    return if quantidade.nil? || valor_unitario.nil?

    self.subtotal = (quantidade.to_d * valor_unitario.to_d).round(2)
  end

  def produto_vendavel
    return if produto.nil?
    return if produto.vendavel?

    errors.add(:produto, "não está disponível para venda")
  end

  def comanda_aberta_para_alteracao
    return if comanda&.aberta?

    errors.add(:comanda, "precisa estar aberta para alterar itens")
  end

  def recalcular_total_da_comanda
    return unless comanda&.aberta?

    begin
      comanda.recalcular_total!
    rescue => e
      Rails.logger.error "Erro ao recalcular total da comanda #{comanda.id}: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end
  end
end
