require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  test "filters periods on desktop" do
    resize_viewport(1440, 1000)
    login
    assert_selector "h1", text: "Dashboard"
    assert_text "Hoje"
    assert_no_horizontal_overflow

    click_link "SEMANA"
    assert_text "Esta semana"
    assert_no_horizontal_overflow

    fill_in "De", with: "01/10/2026"
    fill_in "Até", with: "01/10/2026"
    click_button "FILTRAR"
    assert_text "01/10/2026 – 01/10/2026"
    assert_text "R$ 50,00"
    assert_text "R$ 30,00"
    assert_text "Venda do balcão"
    assert_no_horizontal_overflow
    save_screenshot(Rails.root.join("tmp/screenshots/dashboard-filtro.png"))
  end

  test "dashboard works on mobile" do
    resize_viewport(390, 844)
    login
    assert_selector "h1", text: "Dashboard"
    assert_no_horizontal_overflow
  end
end
