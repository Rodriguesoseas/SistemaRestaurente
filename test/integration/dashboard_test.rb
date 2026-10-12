require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "requires authentication" do
    sign_out :user
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "shows today without next link and empty past days" do
    get dashboard_path
    assert_response :success
    assert_includes response.headers["Content-Security-Policy"], "default-src 'self'"
    assert_select "h1", text: "Dashboard"
    assert_select "h2", text: "Entradas"
    assert_select "p", text: "Hoje"
    assert_select "a", text: "← ANTERIOR"
    assert_select "a", text: "PRÓXIMO →", count: 0

    get dashboard_path, params: { periodo: "hoje", ref: "2026-09-01" }
    assert_response :success
    assert_select "p", text: "01/09/2026"
    assert_select "p", text: "Nenhuma movimentação neste período."
    assert_select "a", text: "PRÓXIMO →"
  end

  test "shows month totals and latest movements for fixture dates" do
    get dashboard_path, params: { periodo: "mes", ref: "2026-10-15" }
    assert_response :success
    assert_select "p", text: "Outubro de 2026"
    assert_select "p", text: "R$ 50,00"
    assert_select "p", text: "R$ 30,00"
    assert_select "p", text: "R$ 20,00"
    assert_select "td", text: /Venda do balcão/
    assert_select "td", text: /Compra de carvão/
    assert_select "a[href*='periodo=semana']", text: "SEMANA"
  end

  test "navigates to previous periods with next link" do
    get dashboard_path, params: { periodo: "mes", ref: "2026-09-10" }
    assert_response :success
    assert_select "p", text: "Setembro de 2026"
    assert_select "p", text: "R$ 0,00"
    assert_select "a", text: "PRÓXIMO →"
  end

  test "filters a custom range" do
    get dashboard_path, params: { periodo: "personalizado", de: "2026-10-01", ate: "2026-10-01" }
    assert_response :success
    assert_select "p", text: "01/10/2026 – 01/10/2026"
    assert_select "p", text: "R$ 50,00"
  end

  test "falls back to hoje with an alert for invalid periods" do
    get dashboard_path, params: { periodo: "personalizado", de: "2026-10-05", ate: "2026-10-01" }
    assert_response :success
    assert_select "p", text: "Hoje"
    assert_select "[role=alert]", text: "Período personalizado inválido. Mostrando hoje."

    get dashboard_path, params: { periodo: "quinzena" }
    assert_response :success
    assert_select "p", text: "Hoje"
  end

  test "shows current caixa and occupied mesas" do
    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    mesas(:mesa_1).comandas.create!(
      caixa: caixa, abertura_user: users(:admin), aberta_em: Time.current, status: Comanda::ABERTA
    )

    get dashboard_path
    assert_response :success
    assert_select "p", text: "R$ 100,00"
    assert_select "h2", text: "Mesas ocupadas"
    assert_select "p", text: /Agora/
  end

  test "shows empty caixa state without an open caixa" do
    get dashboard_path
    assert_response :success
    assert_select "p", text: /Nenhum caixa aberto/
  end
end
