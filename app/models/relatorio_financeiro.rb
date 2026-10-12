class RelatorioFinanceiro
  FUSO = "America/Fortaleza"
  POR_DIA = "dia"
  POR_MES = "mes"
  POR_ANO = "ano"

  attr_reader :filtro

  def initialize(filtro)
    @filtro = filtro
  end

  def base
    MovimentacaoFinanceira.where(ocorrido_em: filtro.intervalo)
  end

  def entradas
    @entradas ||= somar_por_tipo.fetch(MovimentacaoFinanceira::ENTRADA, BigDecimal("0"))
  end

  def saidas
    @saidas ||= somar_por_tipo.fetch(MovimentacaoFinanceira::SAIDA, BigDecimal("0"))
  end

  def resultado
    entradas - saidas
  end

  def dias_corridos
    (fim_data - inicio_data).to_i + 1
  end

  def media_diaria
    return BigDecimal("0") if dias_corridos.zero?

    resultado / dias_corridos
  end

  def caixas_abertos
    Caixa.where(aberto_em: filtro.intervalo).count
  end

  def totais_por_pagamento
    base.entradas.group(:forma_pagamento).sum(:valor)
  end

  def despesas_por_categoria
    base.saidas.joins(:categoria_financeira).group("categoria_financeiras.nome").sum(:valor)
  end

  def granularidade
    return POR_DIA if [ FiltroPeriodo::HOJE, FiltroPeriodo::SEMANA, FiltroPeriodo::MES ].include?(filtro.periodo)
    return POR_MES unless filtro.personalizado?

    dias = dias_corridos
    return POR_DIA if dias <= 31
    return POR_MES if dias <= 366

    POR_ANO
  end

  def rotulos
    case granularidade
    when POR_DIA then dias.map { |data| I18n.l(data, format: "%d/%m") }
    when POR_MES then meses.map { |data| I18n.l(data, format: "%b/%Y") }
    else anos.map(&:to_s)
    end
  end

  def serie_entradas
    montar_serie(MovimentacaoFinanceira::ENTRADA)
  end

  def serie_saidas
    montar_serie(MovimentacaoFinanceira::SAIDA)
  end

  def serie_resultado
    entradas = montar_valores(MovimentacaoFinanceira::ENTRADA)
    saidas = montar_valores(MovimentacaoFinanceira::SAIDA)
    rotulos.zip(entradas.zip(saidas).map { |e, s| (e - s).to_f })
  end

  private

  def somar_por_tipo
    base.group(:tipo).sum(:valor)
  end

  def inicio_data
    filtro.intervalo.begin.to_date
  end

  def fim_data
    filtro.intervalo.end.to_date
  end

  def dias
    inicio_data..fim_data
  end

  def meses
    lista = []
    atual = inicio_data.beginning_of_month
    while atual <= fim_data
      lista << atual
      atual = atual.next_month
    end
    lista
  end

  def anos
    (inicio_data.year..fim_data.year).to_a
  end

  def formato_agrupamento
    case granularidade
    when POR_DIA then "YYYY-MM-DD"
    when POR_MES then "YYYY-MM"
    else "YYYY"
    end
  end

  def timestamp_no_fuso
    # ocorrido_em é timestamp without time zone gravado em wall-UTC:
    # declara como UTC antes de converter para Fortaleza.
    "(ocorrido_em AT TIME ZONE 'UTC') AT TIME ZONE '#{FUSO}'"
  end

  def somas_agrupadas
    # Somente constantes internas são interpoladas (formato e fuso fixos).
    @somas_agrupadas ||= base
      .group(Arel.sql("TO_CHAR(#{timestamp_no_fuso}, '#{formato_agrupamento}')"))
      .group(:tipo)
      .sum(:valor)
  end

  def montar_serie(tipo)
    rotulos.zip(montar_valores(tipo).map(&:to_f))
  end

  def montar_valores(tipo)
    case granularidade
    when POR_DIA
      dias.map { |data| somas_agrupadas.fetch([ data.strftime("%Y-%m-%d"), tipo ], BigDecimal("0")) }
    when POR_MES
      meses.map { |data| somas_agrupadas.fetch([ data.strftime("%Y-%m"), tipo ], BigDecimal("0")) }
    else
      anos.map { |ano| somas_agrupadas.fetch([ ano.to_s, tipo ], BigDecimal("0")) }
    end
  end
end
