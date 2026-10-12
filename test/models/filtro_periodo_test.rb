require "test_helper"

class FiltroPeriodoTest < ActiveSupport::TestCase
  test "defaults to hoje when params are missing or invalid" do
    [ FiltroPeriodo.new, FiltroPeriodo.new(periodo: "quinzena") ].each do |filtro|
      assert_equal "hoje", filtro.periodo
      assert_equal Time.zone.today, filtro.ref
      assert_equal Time.zone.today.all_day, filtro.intervalo
      assert_nil filtro.aviso
    end

    ref_invalido = FiltroPeriodo.new(periodo: "mes", ref: "invalida")
    assert_equal "mes", ref_invalido.periodo
    assert_equal Time.zone.today, ref_invalido.ref
  end

  test "hoje covers the full current day in Fortaleza" do
    filtro = FiltroPeriodo.new
    assert_equal Time.zone.today.beginning_of_day, filtro.intervalo.begin
    assert_equal Time.zone.today.end_of_day, filtro.intervalo.end
    assert_equal 3, filtro.intervalo.begin.utc.hour
    assert filtro.atual?
    assert_equal "Hoje", filtro.descricao
  end

  test "semana starts on monday" do
    filtro = FiltroPeriodo.new(periodo: "semana", ref: "2026-09-15")
    assert_equal Date.new(2026, 9, 14), filtro.intervalo.begin.to_date
    assert_equal Date.new(2026, 9, 20), filtro.intervalo.end.to_date
    assert_equal "14/09/2026 – 20/09/2026", filtro.descricao
  end

  test "mes covers the calendar month including leap february" do
    filtro = FiltroPeriodo.new(periodo: "mes", ref: "2026-02-15")
    assert_equal Date.new(2026, 2, 1), filtro.intervalo.begin.to_date
    assert_equal Date.new(2026, 2, 28), filtro.intervalo.end.to_date
    assert_equal "Fevereiro de 2026", filtro.descricao

    bissexto = FiltroPeriodo.new(periodo: "mes", ref: "2024-02-15")
    assert_equal Date.new(2024, 2, 29), bissexto.intervalo.end.to_date
  end

  test "trimestre follows calendar quarters" do
    filtro = FiltroPeriodo.new(periodo: "trimestre", ref: "2026-05-10")
    assert_equal Date.new(2026, 4, 1), filtro.intervalo.begin.to_date
    assert_equal Date.new(2026, 6, 30), filtro.intervalo.end.to_date
    assert_equal "2º trimestre de 2026", filtro.descricao

    quarto = FiltroPeriodo.new(periodo: "trimestre", ref: "2026-11-20")
    assert_equal Date.new(2026, 10, 1), quarto.intervalo.begin.to_date
    assert_equal Date.new(2026, 12, 31), quarto.intervalo.end.to_date
  end

  test "semestre follows calendar semesters" do
    primeiro = FiltroPeriodo.new(periodo: "semestre", ref: "2026-03-10")
    assert_equal Date.new(2026, 1, 1), primeiro.intervalo.begin.to_date
    assert_equal Date.new(2026, 6, 30), primeiro.intervalo.end.to_date
    assert_equal "1º semestre de 2026", primeiro.descricao

    segundo = FiltroPeriodo.new(periodo: "semestre", ref: "2026-08-10")
    assert_equal Date.new(2026, 7, 1), segundo.intervalo.begin.to_date
    assert_equal Date.new(2026, 12, 31), segundo.intervalo.end.to_date
    assert_equal "2º semestre de 2026", segundo.descricao
  end

  test "ano covers the calendar year" do
    filtro = FiltroPeriodo.new(periodo: "ano", ref: "2026-10-02")
    assert_equal Date.new(2026, 1, 1), filtro.intervalo.begin.to_date
    assert_equal Date.new(2026, 12, 31), filtro.intervalo.end.to_date
    assert_equal "2026", filtro.descricao
  end

  test "personalizado requires valid ordered dates" do
    filtro = FiltroPeriodo.new(periodo: "personalizado", de: "2026-10-01", ate: "2026-10-05")
    assert_equal Date.new(2026, 10, 1), filtro.intervalo.begin.to_date
    assert_equal Date.new(2026, 10, 5), filtro.intervalo.end.to_date
    assert_equal "01/10/2026 – 05/10/2026", filtro.descricao
    assert_nil filtro.aviso

    [ { de: nil, ate: "2026-10-05" }, { de: "2026-10-05", ate: "2026-10-01" }, { de: "xx", ate: "2026-10-05" } ].each do |parametros|
      invalido = FiltroPeriodo.new(periodo: "personalizado", **parametros)
      assert_equal "hoje", invalido.periodo
      assert_equal "Período personalizado inválido. Mostrando hoje.", invalido.aviso
    end
  end

  test "navigates to previous and next references" do
    assert_equal "2026-09-25", FiltroPeriodo.new(periodo: "semana", ref: "2026-10-02").anterior_ref
    assert_equal "2026-10-09", FiltroPeriodo.new(periodo: "semana", ref: "2026-10-02").proximo_ref
    assert_equal "2025-12-15", FiltroPeriodo.new(periodo: "mes", ref: "2026-01-15").anterior_ref
    assert_equal "2026-10-01", FiltroPeriodo.new(periodo: "hoje", ref: "2026-10-02").anterior_ref
    personalizado = FiltroPeriodo.new(periodo: "personalizado", de: "2026-10-01", ate: "2026-10-05")
    assert_equal({ periodo: "personalizado", de: "2026-10-06", ate: "2026-10-10" }, personalizado.proximo_parametros)
    assert_equal({ periodo: "personalizado", de: "2026-09-26", ate: "2026-09-30" }, personalizado.anterior_parametros)
  end

  test "parses itself from request params" do
    filtro = FiltroPeriodo.de_params(ActionController::Parameters.new(periodo: "ano", ref: "2025-06-01"))
    assert_equal "ano", filtro.periodo
    assert_equal Date.new(2025, 6, 1), filtro.ref
    assert_equal({ periodo: "ano", ref: "2025-06-01" }, filtro.parametros_url)
  end
end
