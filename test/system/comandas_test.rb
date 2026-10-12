require "application_system_test_case"

class ComandasTest < ApplicationSystemTestCase
  test "opens orders and pays the comanda on desktop" do
    resize_viewport(1440, 1000)
    login

    click_link "Caixa"
    click_link "ABRIR CAIXA"
    fill_in "Saldo inicial (R$)", with: "100"
    click_button "ABRIR CAIXA"
    assert_selector "h2", text: "Caixa atual"

    click_link "Mesas"
    assert_selector "h1", text: "Mesas"
    within "article", text: "Mesa 1" do
      accept_confirm do
        click_button "ABRIR COMANDA"
      end
    end
    assert_selector "h1", text: "Comanda"
    assert_no_horizontal_overflow

    select "Espeto de carne", from: "Produto"
    fill_in "Quantidade", with: "2"
    click_button "ADICIONAR"
    assert_text "R$ 20,00"
    assert_no_horizontal_overflow

    click_link "PAGAR"
    assert_selector "h1", text: "Pagar comanda"
    select "Pix", from: "Forma de pagamento"
    accept_confirm do
      click_button "CONFIRMAR PAGAMENTO"
    end

    assert_selector "h1", text: "Comanda"
    assert_text "FECHADA"
    assert_text "R$ 20,00"
    assert_no_horizontal_overflow

    click_link "Voltar às mesas"
    assert_selector "h1", text: "Mesas"
    assert_text "LIVRE"
  end
end
