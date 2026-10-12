module HistoricoImutavel
  extend ActiveSupport::Concern

  included do
    before_update :bloquear_alteracao_historica
    before_destroy :bloquear_alteracao_historica, prepend: true
  end

  private

  def bloquear_alteracao_historica
    errors.add(:base, "O histórico não pode ser alterado ou excluído.")
    throw :abort
  end
end
