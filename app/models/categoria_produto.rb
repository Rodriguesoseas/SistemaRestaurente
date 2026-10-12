class CategoriaProduto < ApplicationRecord
  CATEGORIAS = [
    "Carnes", "Espetinhos", "Bebidas", "Carvão",
    "Descartáveis", "Temperos", "Outros"
  ].freeze

  has_many :produtos, dependent: :restrict_with_error

  validates :nome, presence: true, uniqueness: { case_sensitive: false }

  scope :ordenadas, -> { order(:nome) }

  def self.seed_padrao!
    CATEGORIAS.each do |nome|
      find_or_create_by!(nome: nome)
    end
  end
end
