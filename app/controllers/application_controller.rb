class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  allow_browser versions: :modern
  stale_when_importmap_changes

  protected

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def normalize_decimal(value)
    return value if value.blank?

    string = value.to_s.strip
    if string.match?(/\A[+-]?(?:\d+|\d{1,3}(?:\.\d{3})+),\d+\z/)
      string.delete(".").tr(",", ".")
    elsif string.match?(/\A[+-]?\d+(?:\.\d+)?\z/)
      string
    else
      "inválido"
    end
  end
end
