# Rotação operacional local: preserva outras credenciais e nunca imprime valores.
# Execute com: bundle exec rails runner script/rotate_local_secret.rb
abort "Rotação permitida somente em desenvolvimento." unless Rails.env.development?

require "securerandom"
require "yaml"

credentials = Rails.application.credentials
values = credentials.config.deep_stringify_keys
values["secret_key_base"] = SecureRandom.hex(64)
credentials.write(values.to_yaml)
puts "Segredo local rotacionado. Reinicie a aplicação; sessões antigas serão invalidadas."
