require "application_system_test_case"

class EstoquesTest < ApplicationSystemTestCase
  test "registers a stock entrada on desktop" do
    resize_viewport(1440, 1000)
    login

    click_link "Estoque"
    assert_selector "h1", text: "Estoque"
    assert_selector "td", text: "Sem estoque"
    assert_no_horizontal_overflow

    click_link "NOVA MOVIMENTAÇÃO"
    assert_selector "h1", text: "Nova movimentação"
    select "Espeto de carne", from: "Produto"
    select "Entrada", from: "Tipo"
    select "Compra", from: "Motivo"
    fill_in "Quantidade", with: "1,5"
    accept_confirm do
      click_button "REGISTRAR"
    end

    assert_selector "h1", text: "Estoque"
    assert_text "Movimentação de estoque registrada com sucesso."
    assert_selector "td", text: "Espeto de carne"
    assert_no_horizontal_overflow
  end

  test "stock flow works on mobile" do
    resize_viewport(390, 844)
    login
    click_button "Abrir menu"
    click_link "Estoque"
    assert_selector "h1", text: "Estoque"
    assert_no_horizontal_overflow
  end
end
