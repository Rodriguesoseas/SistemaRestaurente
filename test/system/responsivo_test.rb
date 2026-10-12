require "application_system_test_case"

class ResponsivoTest < ApplicationSystemTestCase
  test "todas as páginas sem rolagem horizontal no celular" do
    resize_viewport(390, 844)
    visitar_todas
  end

  test "todas as páginas sem rolagem horizontal no tablet" do
    resize_viewport(768, 1024)
    visitar_todas
  end

  test "todas as páginas sem rolagem horizontal no desktop" do
    resize_viewport(1440, 1000)
    visitar_todas
  end

  private

  def visitar_todas
    login
    visit new_caixa_path
    assert_selector "h1", text: "Abrir caixa"
    assert_no_horizontal_overflow

    caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.current, status: Caixa::ABERTO)
    visit fechar_caixa_path(caixa)
    assert_selector "h1", text: "Fechar caixa"
    assert_no_horizontal_overflow

    comanda = mesas(:mesa_1).comandas.create!(
      caixa: caixa, abertura_user: users(:admin), aberta_em: Time.current, status: Comanda::ABERTA
    )
    comanda.item_comandas.create!(produto: produtos(:espeto), quantidade: 2)

    paginas = [
      [ dashboard_path, "Dashboard" ],
      [ dashboard_path(periodo: "mes", ref: "2026-10-15"), "Dashboard" ],
      [ caixas_path, "Caixa" ],
      [ caixa_path(caixas(:fechado)), "Detalhes do caixa" ],
      [ caixa_path(caixa), "Detalhes do caixa" ],
      [ movimentacao_financeiras_path, "Movimentações" ],
      [ new_movimentacao_financeira_path, "Nova movimentação" ],
      [ movimentacao_financeira_path(movimentacao_financeiras(:venda_dinheiro)), "Detalhes da movimentação" ],
      [ movimentacao_estoques_path, "Estoque" ],
      [ new_movimentacao_estoque_path, "Nova movimentação" ],
      [ movimentacao_estoque_path(movimentacao_estoques(:entrada_cerveja)), "Detalhes da movimentação" ],
      [ produtos_path, "Produtos" ],
      [ new_produto_path, "Novo produto" ],
      [ produto_path(produtos(:espeto)), "Espeto de carne" ],
      [ edit_produto_path(produtos(:espeto)), "Editar produto" ],
      [ mesas_path, "Mesas" ],
      [ new_mesa_path, "Nova mesa" ],
      [ mesa_path(mesas(:mesa_1)), "Mesa" ],
      [ edit_mesa_path(mesas(:mesa_1)), "Editar mesa" ],
      [ comandas_path, "Comandas" ],
      [ comanda_path(comanda), "Comanda" ],
      [ comanda_path(comandas(:fechada_mesa2)), "Comanda" ],
      [ pagar_comanda_path(comanda), "Pagar comanda" ],
      [ relatorios_path, "Relatórios" ],
      [ relatorios_path(periodo: "personalizado", de: "2026-10-01", ate: "2026-10-01"), "Relatórios" ]
    ]

    paginas.each do |caminho, titulo|
      visit caminho
      assert_selector "h1", text: titulo
      assert_no_horizontal_overflow
    end
  end
end
