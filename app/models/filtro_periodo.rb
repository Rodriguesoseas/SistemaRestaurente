class FiltroPeriodo
  HOJE = "hoje"
  SEMANA = "semana"
  MES = "mes"
  TRIMESTRE = "trimestre"
  SEMESTRE = "semestre"
  ANO = "ano"
  PERSONALIZADO = "personalizado"
  PERIODOS = [ HOJE, SEMANA, MES, TRIMESTRE, SEMESTRE, ANO, PERSONALIZADO ].freeze

  ROTULOS_PERIODO = {
    HOJE => "Hoje",
    SEMANA => "Semana",
    MES => "Mês",
    TRIMESTRE => "Trimestre",
    SEMESTRE => "Semestre",
    ANO => "Ano",
    PERSONALIZADO => "Personalizado"
  }.freeze

  attr_reader :periodo, :ref, :de, :ate, :aviso

  def self.de_params(params)
    new(
      periodo: params[:periodo],
      ref: params[:ref],
      de: params[:de],
      ate: params[:ate]
    )
  end

  def initialize(periodo: nil, ref: nil, de: nil, ate: nil)
    @periodo = PERIODOS.include?(periodo) ? periodo : HOJE
    @ref = parse_data(ref) || hoje
    @de = parse_data(de)
    @ate = parse_data(ate)
    @aviso = nil
    validar_personalizado
  end

  def personalizado?
    periodo == PERSONALIZADO
  end

  def intervalo
    inicio = inicio_do_intervalo
    fim = fim_do_intervalo
    inicio.beginning_of_day..fim.end_of_day
  end

  def descricao
    inicio = inicio_do_intervalo.to_date
    fim = fim_do_intervalo.to_date
    case periodo
    when HOJE then atual? ? "Hoje" : I18n.l(inicio)
    when SEMANA then atual? ? "Esta semana" : "#{I18n.l(inicio)} – #{I18n.l(fim)}"
    when MES then I18n.l(inicio, format: "%B de %Y").capitalize
    when TRIMESTRE then "#{((inicio.month - 1) / 3) + 1}º trimestre de #{inicio.year}"
    when SEMESTRE then "#{inicio.month <= 6 ? 1 : 2}º semestre de #{inicio.year}"
    when ANO then inicio.year.to_s
    else "#{I18n.l(inicio)} – #{I18n.l(fim)}"
    end
  end

  def atual?
    intervalo.cover?(Time.current)
  end

  def anterior_ref
    deslocar_ref(-1).iso8601
  end

  def proximo_ref
    deslocar_ref(1).iso8601
  end

  def anterior_parametros
    if personalizado?
      dias = ((ate - de).to_i + 1).days
      { periodo: PERSONALIZADO, de: (de - dias).iso8601, ate: (ate - dias).iso8601 }
    else
      parametros_url.merge(ref: anterior_ref)
    end
  end

  def proximo_parametros
    if personalizado?
      dias = ((ate - de).to_i + 1).days
      { periodo: PERSONALIZADO, de: (de + dias).iso8601, ate: (ate + dias).iso8601 }
    else
      parametros_url.merge(ref: proximo_ref)
    end
  end

  def parametros_url
    { periodo: periodo, ref: ref.iso8601, de: de&.iso8601, ate: ate&.iso8601 }.compact
  end

  private

  def hoje
    Time.zone.today
  end

  def parse_data(valor)
    return nil if valor.blank?
    string = valor.to_s.strip
    return nil unless string.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    data = Date.iso8601(string)
    (1900..2100).cover?(data.year) ? data : nil
  rescue Date::Error, ArgumentError
    nil
  end

  def validar_personalizado
    return unless personalizado?
    return if de && ate && de <= ate

    @periodo = HOJE
    @ref = hoje
    @de = nil
    @ate = nil
    @aviso = "Período personalizado inválido. Mostrando hoje."
  end

  def inicio_do_intervalo
    case periodo
    when SEMANA then ref.beginning_of_week(:monday)
    when MES then ref.beginning_of_month
    when TRIMESTRE then ref.beginning_of_quarter
    when SEMESTRE then ref.beginning_of_year + ((ref.month - 1) / 6 * 6).months
    when ANO then ref.beginning_of_year
    when PERSONALIZADO then de
    else ref
    end
  end

  def fim_do_intervalo
    case periodo
    when SEMANA then ref.end_of_week(:monday)
    when MES then ref.end_of_month
    when TRIMESTRE then ref.end_of_quarter
    when SEMESTRE then (inicio_do_intervalo + 6.months - 1.day).end_of_day
    when ANO then ref.end_of_year
    when PERSONALIZADO then ate
    else ref
    end
  end

  def deslocar_ref(direcao)
    case periodo
    when SEMANA then ref + direcao.weeks
    when MES then ref + direcao.months
    when TRIMESTRE then ref + (direcao * 3).months
    when SEMESTRE then ref + (direcao * 6).months
    when ANO then ref + direcao.years
    else ref + direcao.days
    end
  end
end
