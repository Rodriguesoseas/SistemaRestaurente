require "application_system_test_case"

class CaixasTest < ApplicationSystemTestCase
  test "opens checks and closes the caixa on desktop" do
    resize_viewport(1440, 1000)
    login

    click_link "Caixa"
    assert_selector "h2", text: "Nenhum caixa aberto"

    click_link "ABRIR CAIXA"
    assert_selector "h1", text: "Abrir caixa"
    fill_in "Saldo inicial (R$)", with: "100"
    click_button "ABRIR CAIXA"

    assert_selector "h2", text: "Caixa atual"
    assert_text "R$ 100,00"
    assert_no_horizontal_overflow

    click_link "FECHAR CAIXA"
    assert_selector "h1", text: "Fechar caixa"
    fill_in "Valor contado em dinheiro (R$)", with: "95"
    accept_confirm do
      click_button "CONFIRMAR FECHAMENTO"
    end

    assert_selector "h1", text: "Detalhes do caixa"
    assert_text "Fechado"
    assert_text "-R$ 5,00"
    assert_no_horizontal_overflow

    click_link "Voltar ao caixa"
    assert_selector "h2", text: "Histórico de caixas"
    assert_selector "td", text: "-R$ 5,00"
    assert_selector "span", text: "Fechado"
  end

  test "caixa flow works on mobile" do
    resize_viewport(390, 844)
    login
    click_button "Abrir menu"
    click_link "Caixa"
    assert_selector "h1", text: "Caixa"
    assert_no_horizontal_overflow

    click_link "ABRIR CAIXA"
    fill_in "Saldo inicial (R$)", with: "50"
    click_button "ABRIR CAIXA"
    assert_selector "h2", text: "Caixa atual"
    assert_no_horizontal_overflow
  end
end
