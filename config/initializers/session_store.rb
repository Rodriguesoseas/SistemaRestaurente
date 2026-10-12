Rails.application.config.session_store :cookie_store,
  key: "_espetaria_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  # Teto absoluto da sessão; o limite de inatividade (30 min) é aplicado
  # pelo Devise :timeoutable para que o usuário veja a mensagem de expiração.
  expire_after: 8.hours
