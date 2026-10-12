require "test_helper"

class RelatorioFinanceiroTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 15, 12)
    MovimentacaoFinanceira.delete_all
    @caixa = Caixa.create!(user: users(:admin), saldo_inicial: 100, aberto_em: Time.zone.local(2026, 10, 5), status: Caixa::ABERTO)
    CategoriaFinanceira.seed_padrao!
  end

  teardown do
    travel_back
  end

  def criar_movimentacao(tipo:, valor:, ocorrido_em:, categoria: nil, forma: nil)
    categoria ||= tipo == "entrada" ? categoria_financeiras(:venda) : categoria_financeiras(:carvao)
    forma ||= tipo == "entrada" ? "dinheiro" : "nao_informada"
    MovimentacaoFinanceira.create!(
      caixa: @caixa, user: users(:admin), categoria_financeira: categoria,
      tipo: tipo, descricao: "Teste", valor: valor, forma_pagamento: forma,
      ocorrido_em: ocorrido_em
    )
  end

  def relatorio(periodo: "mes", ref: "2026-10-15", de: nil, ate: nil)
    RelatorioFinanceiro.new(FiltroPeriodo.new(periodo: periodo, ref: ref, de: de, ate: ate))
  end

  test "uses day granularity for hoje semana mes and month counts" do
    assert_equal "dia", relatorio(periodo: "hoje").granularidade
    assert_equal 1, relatorio(periodo: "hoje", ref: "2026-10-02").rotulos.size

    semana = relatorio(periodo: "semana", ref: "2026-09-15")
    assert_equal "dia", semana.granularidade
    assert_equal 7, semana.rotulos.size
    assert_equal "14/09", semana.rotulos.first

    mes = relatorio(ref: "2026-10-15")
    assert_equal "dia", mes.granularidade
    assert_equal 31, mes.rotulos.size

    fevereiro = relatorio(ref: "2024-02-15")
    assert_equal 29, fevereiro.rotulos.size
  end

  test "uses month granularity for trimestre semestre ano" do
    assert_equal "mes", relatorio(periodo: "trimestre", ref: "2026-05-10").granularidade
    assert_equal 3, relatorio(periodo: "trimestre", ref: "2026-05-10").rotulos.size
    assert_equal "mes", relatorio(periodo: "semestre", ref: "2026-08-10").granularidade
    assert_equal 6, relatorio(periodo: "semestre", ref: "2026-08-10").rotulos.size

    ano = relatorio(periodo: "ano", ref: "2026-10-02")
    assert_equal "mes", ano.granularidade
    assert_equal 12, ano.rotulos.size
    assert_equal "out/2026", ano.rotulos[9]
  end

  test "custom granularity follows the 31 and 366 day limits" do
    assert_equal "dia", relatorio(periodo: "personalizado", de: "2026-10-01", ate: "2026-10-31").granularidade
    assert_equal "mes", relatorio(periodo: "personalizado", de: "2026-10-01", ate: "2026-11-01").granularidade
    assert_equal "mes", relatorio(periodo: "personalizado", de: "2025-10-02", ate: "2026-10-02").granularidade
    longo = relatorio(periodo: "personalizado", de: "2025-10-01", ate: "2026-10-02")
    assert_equal "ano", longo.granularidade
    assert_equal %w[2025 2026], longo.rotulos
  end

  test "fills empty intervals with zero across the year boundary" do
    criar_movimentacao(tipo: "entrada", valor: 50, ocorrido_em: Time.zone.local(2025, 12, 31, 10))
    rel = relatorio(periodo: "personalizado", de: "2025-12-30", ate: "2026-01-02")
    assert_equal [ "30/12", "31/12", "01/01", "02/01" ], rel.rotulos
    assert_equal [ [ "30/12", 0.0 ], [ "31/12", 50.0 ], [ "01/01", 0.0 ], [ "02/01", 0.0 ] ], rel.serie_entradas
    assert_equal [ [ "30/12", 0.0 ], [ "31/12", 0.0 ], [ "01/01", 0.0 ], [ "02/01", 0.0 ] ], rel.serie_saidas
  end

  test "sums series by day with movement values" do
    criar_movimentacao(tipo: "entrada", valor: 50, ocorrido_em: Time.zone.local(2026, 10, 1, 10))
    criar_movimentacao(tipo: "saida", valor: 30, ocorrido_em: Time.zone.local(2026, 10, 1, 11))
    criar_movimentacao(tipo: "entrada", valor: 20, ocorrido_em: Time.zone.local(2026, 10, 3, 10))
    rel = relatorio(ref: "2026-10-15")
    assert_equal BigDecimal("70"), rel.entradas
    assert_equal BigDecimal("30"), rel.saidas
    assert_equal BigDecimal("40"), rel.resultado
    assert_equal [ "01/10", 50.0 ], rel.serie_entradas.first
    assert_equal [ "03/10", 20.0 ], rel.serie_entradas[2]
    assert_equal [ "02/10", 0.0 ], rel.serie_entradas[1]
    assert_equal [ "01/10", 20.0 ], rel.serie_resultado.first
  end

  test "groups by Fortaleza date not UTC" do
    criar_movimentacao(tipo: "entrada", valor: 50, ocorrido_em: Time.zone.local(2026, 10, 1, 23, 30))
    rel = relatorio(periodo: "personalizado", de: "2026-10-01", ate: "2026-10-02")
    assert_equal [ [ "01/10", 50.0 ], [ "02/10", 0.0 ] ], rel.serie_entradas
  end

  test "computes daily average over elapsed days including empty ones" do
    criar_movimentacao(tipo: "entrada", valor: 50, ocorrido_em: Time.zone.local(2026, 10, 1, 10))
    criar_movimentacao(tipo: "saida", valor: 30, ocorrido_em: Time.zone.local(2026, 10, 1, 11))
    rel = relatorio(ref: "2026-10-15")
    assert_equal 31, rel.dias_corridos
    assert_equal BigDecimal("20") / 31, rel.media_diaria
  end

  test "counts open caixas and groups payments and expense categories" do
    criar_movimentacao(tipo: "entrada", valor: 50, ocorrido_em: Time.zone.local(2026, 10, 1, 10), forma: "pix")
    criar_movimentacao(tipo: "saida", valor: 30, ocorrido_em: Time.zone.local(2026, 10, 1, 11))
    rel = relatorio(ref: "2026-10-15")
    assert_equal 2, rel.caixas_abertos
    assert_equal({ "pix" => BigDecimal("50") }, rel.totais_por_pagamento)
    assert_equal({ "Carvão" => BigDecimal("30") }, rel.despesas_por_categoria)
  end
end
