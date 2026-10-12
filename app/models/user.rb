class User < ApplicationRecord
  devise :database_authenticatable, :validatable, :lockable, :timeoutable

  has_many :caixas, dependent: :restrict_with_error

  before_validation :normalizar_email

  private

  def normalizar_email
    self.email = email.to_s.strip.downcase
  end
end
