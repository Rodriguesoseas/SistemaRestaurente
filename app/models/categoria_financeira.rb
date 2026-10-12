class CategoriaFinanceira < ApplicationRecord
  ENTRADA = "entrada"
  SAIDA = "saida"
  TIPOS = [ ENTRADA, SAIDA ].freeze

  CATEGORIAS_ENTRADA = [ "Venda", "Outros" ].freeze
  CATEGORIAS_SAIDA = [
    "Mercadoria", "Carnes", "Bebidas", "Carvão", "Gás", "Energia",
    "Fornecedor", "Manutenção", "Funcionários", "Outros"
  ].freeze

  has_many :movimentacao_financeiras, dependent: :restrict_with_error

  validates :nome, presence: true, uniqueness: { scope: :tipo, case_sensitive: false }
  validates :tipo, inclusion: { in: TIPOS }

  scope :entradas, -> { where(tipo: ENTRADA).order(:nome) }
  scope :saidas, -> { where(tipo: SAIDA).order(:nome) }
  scope :ordenadas, -> { order(:tipo, :nome) }

  def self.rotulo_tipo(tipo)
    tipo == ENTRADA ? "Entrada" : "Saída"
  end

  def self.seed_padrao!
    CATEGORIAS_ENTRADA.each do |nome|
      find_or_create_by!(tipo: ENTRADA, nome: nome)
    end
    CATEGORIAS_SAIDA.each do |nome|
      find_or_create_by!(tipo: SAIDA, nome: nome)
    end
  end
end
