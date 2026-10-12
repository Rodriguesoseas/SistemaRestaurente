require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a valid email and a password of at least eight characters" do
    user = User.new(email: "invalido", password: "curta")
    assert_not user.valid?
    assert user.errors.added?(:email, :invalid, value: "invalido")
    assert user.errors[:password].any?

    user.email = ""
    user.password = ""
    assert_not user.valid?
    assert user.errors[:email].any?
    assert user.errors[:password].any?
  end

  test "normalizes email and prevents duplicate accounts" do
    user = User.new(email: "  ADMIN@EXAMPLE.TEST  ", password: "OutraSenha123!")
    assert_not user.valid?
    assert_equal "admin@example.test", user.email
    assert user.errors[:email].any?
  end

  test "database also enforces case insensitive email uniqueness" do
    assert_raises ActiveRecord::RecordNotUnique do
      User.insert_all!([ { email: "ADMIN@EXAMPLE.TEST", encrypted_password: users(:admin).encrypted_password } ])
    end
  end

  test "authenticates the saved hash without storing the plain password" do
    user = User.create!(email: "novo@example.test", password: "SenhaSegura123!")
    assert user.reload.valid_password?("SenhaSegura123!")
    assert_not_equal "SenhaSegura123!", user.encrypted_password
    assert_not user.valid_password?("errada")
  end
end
