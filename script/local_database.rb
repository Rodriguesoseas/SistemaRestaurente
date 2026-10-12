# Local Windows PostgreSQL management. Binaries live outside version control.
require "fileutils"
require "securerandom"
require "tempfile"
require "dotenv"
require "pg"

root = File.expand_path("..", __dir__)
local = File.join(root, ".local")
bin = File.join(local, "pgsql", "bin")
data = File.join(local, "postgres-data")
env_file = File.join(root, ".env.local")
command = ARGV.fetch(0, "start")
abort "Use: bundle exec ruby script/local_database.rb [setup|start|stop|status]" unless %w[setup start stop status].include?(command)
abort "Instale os binários PostgreSQL em .local/pgsql (consulte o README)." unless File.exist?(File.join(bin, "pg_ctl.exe"))

Dotenv.load(env_file)
port = ENV.fetch("PGPORT", "5433")
ctl = File.join(bin, "pg_ctl.exe")

if command == "setup"
  abort "Já existe configuração local. Use start." if File.exist?(env_file) || File.exist?(data) || File.exist?(File.join(root, ".env.test.local"))
  admin_password = SecureRandom.hex(32)
  app_password = SecureRandom.hex(32)
  Tempfile.create("espetaria-pg-password") do |file|
    file.write(admin_password)
    file.flush
    system(File.join(bin, "initdb.exe"), "-D", data, "-U", "postgres", "--pwfile=#{file.path}", "--auth=scram-sha-256", "--encoding=UTF8", "--locale=C", exception: true)
  end
  system(ctl, "-D", data, "-l", File.join(local, "postgres.log"), "-o", "-h 127.0.0.1 -p #{port}", "-w", "start", exception: true)
  PG.connect(host: "127.0.0.1", port: port, user: "postgres", password: admin_password, dbname: "postgres") do |connection|
    # Rails needs to disable referential integrity to load test fixtures, which
    # requires a superuser. This role is local-only and never used in production.
    connection.exec("CREATE ROLE espetaria LOGIN CREATEDB SUPERUSER PASSWORD #{connection.escape_literal(app_password)}")
  end
  # Generated passwords are never printed or committed. Keep the cluster's
  # maintenance credential separately from the application's restricted role.
  File.write(File.join(local, "postgres-admin-password"), admin_password, mode: "wx", perm: 0o600)
  File.write(env_file, "PGHOST=127.0.0.1\nPGPORT=#{port}\nPGUSER=espetaria\nPGPASSWORD=#{app_password}\nADMIN_EMAIL=admin@espetaria.local\nADMIN_PASSWORD=#{SecureRandom.urlsafe_base64(24)}\n", mode: "wx", perm: 0o600)
  File.write(File.join(root, ".env.test.local"), "PGHOST=127.0.0.1\nPGPORT=#{port}\nPGUSER=espetaria\nPGPASSWORD=#{app_password}\n", mode: "wx", perm: 0o600)
  puts "PostgreSQL configurado. Credenciais locais em .env.local (ignorado pelo Git)."
elsif command == "start"
  if system(ctl, "-D", data, "status", out: File::NULL, err: File::NULL)
    puts "PostgreSQL já está em execução."
  else
    system(ctl, "-D", data, "-l", File.join(local, "postgres.log"), "-o", "-h 127.0.0.1 -p #{port}", "-w", "start", exception: true)
  end
elsif command == "stop"
  system(ctl, "-D", data, "-m", "fast", "-w", "stop", exception: true)
else
  system(ctl, "-D", data, "status", exception: true)
end
