require "test_helper"

class CaixasTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "requires authentication" do
    sign_out :user
    get caixas_path
    assert_redirected_to new_user_session_path
  end

  test "shows empty state and opens a caixa" do
    get caixas_path
    assert_response :success
    assert_select "h2", text: "Nenhum caixa aberto"

    assert_difference "Caixa.count", 1 do
      post caixas_path, params: { caixa: { saldo_inicial: "100,00" } }
    end
    caixa = Caixa.atual
    assert_redirected_to caixa_path(caixa)
    assert_equal "aberto", caixa.status
    assert_equal users(:admin), caixa.user
    assert_equal BigDecimal("100.00"), caixa.saldo_inicial
    assert_equal 100.to_d, caixa.dinheiro_esperado
  end

  test "does not open a second caixa" do
    Caixa.create!(user: users(:admin), saldo_inicial: 50, aberto_em: Time.current, status: Caixa::ABERTO)

    assert_no_difference "Caixa.count" do
      post caixas_path, params: { caixa: { saldo_inicial: "10,00" } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]"

    get new_caixa_path
    assert_redirected_to caixa_path(Caixa.atual)
  end

  test "recovers gracefully from a concurrent open" do
    Caixa.create!(user: users(:admin), saldo_inicial: 50, aberto_em: Time.current, status: Caixa::ABERTO)

    original = Caixa.method(:aberto)
    Caixa.define_singleton_method(:aberto) { Caixa.none }
    begin
      assert_no_difference "Caixa.count" do
        post caixas_path, params: { caixa: { saldo_inicial: "10,00" } }
      end
    ensure
      Caixa.define_singleton_method(:aberto, original)
    end
    assert_redirected_to caixas_path
  end

  test "rejects a negative opening balance" do
    assert_no_difference "Caixa.count" do
      post caixas_path, params: { caixa: { saldo_inicial: "-5" } }
    end
    assert_response :unprocessable_content
  end

  test "closes the caixa with counted money and difference" do
    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)

    get fechar_caixa_path(caixa)
    assert_response :success
    assert_select "input[name='caixa[valor_contado]']"

    patch confirmar_fechamento_caixa_path(caixa), params: { caixa: { valor_contado: "95,00" } }
    assert_redirected_to caixa_path(caixa)
    caixa.reload
    assert caixa.fechado?
    assert_equal BigDecimal("100.00"), caixa.valor_esperado_dinheiro
    assert_equal BigDecimal("95.00"), caixa.valor_contado
    assert_equal BigDecimal("-5.00"), caixa.diferenca
    assert_equal users(:admin), caixa.fechamento_user
    assert_not_nil caixa.fechado_em
  end

  test "requires counted money to close" do
    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    assert_no_changes -> { caixa.reload.status } do
      patch confirmar_fechamento_caixa_path(caixa), params: { caixa: { valor_contado: "" } }
    end
    assert_response :unprocessable_content
  end

  test "does not close an already closed caixa" do
    caixa = caixas(:fechado)
    patch confirmar_fechamento_caixa_path(caixa), params: { caixa: { valor_contado: "10" } }
    assert_redirected_to caixa_path(caixa)
    assert caixa.reload.fechado?
    assert_equal BigDecimal("95.00"), caixa.valor_contado
  end

  test "lists history and shows details" do
    get caixas_path
    assert_response :success
    assert_select "h2", text: "Histórico de caixas"
    assert_select "td", text: "admin@example.test"

    get caixa_path(caixas(:fechado))
    assert_response :success
    assert_select "h1", text: "Detalhes do caixa"
    assert_select "dd", text: "R$ 95,00"
  end
end
