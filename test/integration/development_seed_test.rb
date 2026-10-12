require "test_helper"

class DevelopmentSeedTest < ActiveSupport::TestCase
  setup do
    @original_environment = Rails.env
    @original_email = ENV["ADMIN_EMAIL"]
    @original_password = ENV["ADMIN_PASSWORD"]
    Rails.env = "development"
    ENV["ADMIN_EMAIL"] = "seed@example.test"
    ENV["ADMIN_PASSWORD"] = "SenhaSeedTeste123!"
  end

  teardown do
    Rails.env = @original_environment
    ENV["ADMIN_EMAIL"] = @original_email
    ENV["ADMIN_PASSWORD"] = @original_password
  end

  test "creates the admin once and preserves the existing password" do
    assert_difference "User.count", 1 do
      capture_io { load Rails.root.join("db/seeds.rb") }
    end
    admin = User.find_by!(email: ENV["ADMIN_EMAIL"])
    original_hash = admin.encrypted_password

    ENV["ADMIN_PASSWORD"] = "UmaNovaSenha123!"
    assert_no_difference "User.count" do
      capture_io { load Rails.root.join("db/seeds.rb") }
    end
    assert_equal original_hash, admin.reload.encrypted_password
    assert admin.valid_password?("SenhaSeedTeste123!")
  end

  test "requires explicit credentials for a new administrator" do
    ENV.delete("ADMIN_PASSWORD")
    assert_no_difference "User.count" do
      assert_raises(KeyError, RuntimeError) { load Rails.root.join("db/seeds.rb") }
    end
  end

  test "does not create demo accounts in production" do
    Rails.env = "production"
    assert_no_difference "User.count" do
      capture_io { load Rails.root.join("db/seeds.rb") }
    end
  end

  test "seeds demo products and mesas in development" do
    capture_io { load Rails.root.join("db/seeds.rb") }
    assert Produto.exists?(nome: "Espeto de carne")
    assert_equal BigDecimal("10"), Produto.find_by!(nome: "Espeto de carne").preco_venda
    assert_not Produto.find_by!(nome: "Carvão").disponivel_venda?
    assert Mesa.exists?(numero: 1)
    assert_equal 5, Mesa.count
  end

  test "seeds default financial categories idempotently" do
    assert_difference "CategoriaFinanceira.count", 8 do
      capture_io { load Rails.root.join("db/seeds.rb") }
    end
    assert_no_difference "CategoriaFinanceira.count" do
      capture_io { load Rails.root.join("db/seeds.rb") }
    end
    assert_equal 2, CategoriaFinanceira.where(tipo: "entrada").count
    assert_equal 10, CategoriaFinanceira.where(tipo: "saida").count
  end
end
