require "application_system_test_case"

class AccessTest < ApplicationSystemTestCase
  test "desktop login dashboard and logout" do
    resize_viewport(1440, 1000)
    login
    assert_selector "nav[aria-label='Menu principal']"
    assert_selector "article", count: 6
    assert_no_text "Aguardando configuração do módulo"
    assert_selector "h2", text: "Entradas"
    assert_selector "h2", text: "Últimas movimentações"
    assert_selector "h2", text: "Estoque baixo"
    assert_no_horizontal_overflow
    save_screenshot(Rails.root.join("tmp/screenshots/dashboard-desktop.png"))
    click_button "Sair"
    assert_selector "h1", text: "Bem-vindo de volta"
    visit dashboard_path
    assert_current_path new_user_session_path
  end

  test "mobile menu opens closes with Escape and supports logout" do
    resize_viewport(390, 844)
    visit new_user_session_path
    assert_no_horizontal_overflow
    save_screenshot(Rails.root.join("tmp/screenshots/login-mobile.png"))
    login
    assert_no_selector "nav[aria-label='Menu principal']"
    click_button "Abrir menu"
    assert_selector "button[aria-expanded=true]"
    assert_selector "nav[aria-label='Menu principal']"
    assert_no_horizontal_overflow
    page.driver.browser.action.send_keys(:escape).perform
    assert_no_selector "nav[aria-label='Menu principal']"
    assert_selector "button[aria-expanded=false]"
    save_screenshot(Rails.root.join("tmp/screenshots/dashboard-mobile.png"))
    click_button "Abrir menu"
    click_button "Sair"
    assert_selector "h1", text: "Bem-vindo de volta"
  end

  test "tablet layout and invalid password feedback" do
    resize_viewport(768, 1024)
    visit new_user_session_path
    fill_in "E-mail", with: users(:admin).email
    fill_in "Senha", with: "SenhaIncorreta"
    click_button "ENTRAR"
    assert_selector "[role=alert]", text: "E-mail ou senha inválidos."
    assert_no_horizontal_overflow
    fill_in "Senha", with: "SenhaDeTeste123!"
    click_button "ENTRAR"
    assert_selector "h1", text: "Dashboard"
    assert_no_horizontal_overflow
    click_button "Abrir menu"
    assert_selector "nav[aria-label='Menu principal']"
    save_screenshot(Rails.root.join("tmp/screenshots/dashboard-tablet.png"))
  end
end
