CategoriaFinanceira.seed_padrao!
puts "Categorias financeiras verificadas."
CategoriaProduto.seed_padrao!
puts "Categorias de produtos verificadas."

if Rails.env.development?
  produtos_iniciais = [
    { nome: "Espeto de carne", categoria: "Espetinhos", unidade: "unidade", preco_venda: "10.00" },
    { nome: "Espeto de frango", categoria: "Espetinhos", unidade: "unidade", preco_venda: "9.00" },
    { nome: "Cerveja", categoria: "Bebidas", unidade: "garrafa", preco_venda: "8.00" },
    { nome: "Refrigerante", categoria: "Bebidas", unidade: "garrafa", preco_venda: "6.00" }
  ]
  produtos_iniciais.each do |atributos|
    categoria = CategoriaProduto.find_by!(nome: atributos[:categoria])
    Produto.find_or_create_by!(nome: atributos[:nome]) do |produto|
      produto.categoria_produto = categoria
      produto.unidade = atributos[:unidade]
      produto.preco_venda = atributos[:preco_venda]
    end
  end
  carvao = CategoriaProduto.find_by!(nome: "Carvão")
  Produto.find_or_create_by!(nome: "Carvão") do |produto|
    produto.categoria_produto = carvao
    produto.unidade = "pacote"
    produto.disponivel_venda = false
    produto.preco_venda = nil
  end
  puts "Produtos de demonstração verificados."

  (1..5).each do |numero|
    Mesa.find_or_create_by!(numero: numero)
  end
  puts "Mesas de demonstração verificadas."

  email = ENV.fetch("ADMIN_EMAIL") { raise "Defina ADMIN_EMAIL para criar o administrador de desenvolvimento." }.strip.downcase
  raise "ADMIN_EMAIL não pode ficar vazio." if email.blank?

  user = User.find_or_initialize_by(email: email)
  if user.new_record?
    user.password = ENV.fetch("ADMIN_PASSWORD") { raise "Defina ADMIN_PASSWORD para criar o administrador de desenvolvimento." }
    user.save!
    puts "Administrador de desenvolvimento criado."
  else
    puts "Administrador já cadastrado; senha preservada."
  end
else
  puts "Seed de desenvolvimento ignorado neste ambiente. Crie o administrador de produção pelo console."
end
