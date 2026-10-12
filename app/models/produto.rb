class Produto < ApplicationRecord
  UNIDADES = %w[unidade kg litro pacote caixa garrafa outro].freeze

  ROTULOS_UNIDADE = {
    "unidade" => "Unidade",
    "kg" => "Kg",
    "litro" => "Litro",
    "pacote" => "Pacote",
    "caixa" => "Caixa",
    "garrafa" => "Garrafa",
    "outro" => "Outro"
  }.freeze

  belongs_to :categoria_produto
  has_many :item_comandas, dependent: :restrict_with_error
  has_many :movimentacao_estoques, dependent: :restrict_with_error

  validates :nome, presence: true
  validates :unidade, inclusion: { in: UNIDADES }
  validates :ativo, inclusion: { in: [ true, false ] }
  validates :disponivel_venda, inclusion: { in: [ true, false ] }
  validates :quantidade_atual, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :estoque_minimo, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :preco_custo, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :preco_venda, presence: true, if: :disponivel_venda
  validates :preco_venda, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :preco_custo, :preco_venda, decimal_seguro: true, allow_nil: true
  validates :quantidade_atual, :estoque_minimo, decimal_seguro: { scale: 3 }

  scope :ativos, -> { where(ativo: true).order(:nome) }
  scope :vendaveis, -> { where(ativo: true, disponivel_venda: true).order(:nome) }
  scope :ordenados, -> { order(:nome) }
  scope :com_estoque_baixo, -> { where(ativo: true).where("quantidade_atual <= estoque_minimo").order(:nome) }

  def vendavel?
    ativo? && disponivel_venda?
  end

  def estoque_status
    return :sem_estoque if quantidade_atual <= 0
    return :baixo if quantidade_atual <= estoque_minimo

    :normal
  end

  def sem_estoque?
    estoque_status == :sem_estoque
  end

  def estoque_baixo?
    estoque_status == :baixo
  end

  def unidade_rotulo
    ROTULOS_UNIDADE.fetch(unidade, unidade)
  end
end
