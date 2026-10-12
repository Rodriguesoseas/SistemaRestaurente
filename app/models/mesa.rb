class Mesa < ApplicationRecord
  has_many :comandas, dependent: :restrict_with_error
  has_one :comanda_aberta, -> { where(status: Comanda::ABERTA) }, class_name: "Comanda", dependent: nil

  validates :numero, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :ativo, inclusion: { in: [ true, false ] }

  scope :ordenadas, -> { order(:numero) }

  def ocupada?
    comanda_aberta.present?
  end

  def livre?
    !ocupada?
  end
end
