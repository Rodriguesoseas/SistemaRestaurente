require "application_system_test_case"

class RelatoriosTest < ApplicationSystemTestCase
  test "renders charts on desktop" do
    resize_viewport(1440, 1000)
    login

    click_link "Relatórios"
    assert_selector "h1", text: "Relatórios"
    assert_selector "div[data-controller='chart']", count: 2
    assert_selector "canvas", minimum: 1
    assert_text "Média diária"
    assert_no_horizontal_overflow
    save_screenshot(Rails.root.join("tmp/screenshots/relatorios-desktop.png"))

    click_link "MÊS"
    assert_text "Outubro de 2026"
    assert_selector "canvas", minimum: 1
    assert_no_horizontal_overflow
  end

  test "reports work on mobile" do
    resize_viewport(390, 844)
    login
    click_button "Abrir menu"
    click_link "Relatórios"
    assert_selector "h1", text: "Relatórios"
    assert_selector "div[data-controller='chart']", count: 2
    assert_no_horizontal_overflow
  end
end
