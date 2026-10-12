class CaixasController < ApplicationController
  before_action :set_caixa, only: [ :show, :fechar, :confirmar_fechamento ]

  def index
    @caixa_atual = Caixa.atual
    @caixas = Caixa.includes(:user).recentes
  end

  def new
    if Caixa.atual
      redirect_to caixa_path(Caixa.atual), notice: "Já existe um caixa aberto."
      return
    end
    @caixa = Caixa.new
  end

  def create
    @caixa = Caixa.new(caixa_params)
    @caixa.user = current_user
    @caixa.status = Caixa::ABERTO
    @caixa.aberto_em = Time.current

    if @caixa.save
      redirect_to caixa_path(@caixa), notice: "Caixa aberto com sucesso."
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to caixas_path, alert: "Já existe um caixa aberto."
  end

  def show
    @movimentacoes = @caixa.movimentacao_financeiras.includes(:categoria_financeira).recentes
  end

  def fechar
    if @caixa.fechado?
      redirect_to caixa_path(@caixa), alert: "Este caixa já está fechado."
      return
    end
    if (pendentes = @caixa.comandas_pendentes).any?
      redirect_to caixa_path(@caixa), alert: "Há comandas abertas neste caixa (#{pendentes.map { |c| "Mesa #{c.mesa.numero}" }.join(", ")}). Finalize-as antes de fechar o caixa."
    end
  end

  def confirmar_fechamento
    if @caixa.fechado?
      redirect_to caixa_path(@caixa), alert: "Este caixa já está fechado."
      return
    end

    if (pendentes = @caixa.comandas_pendentes).any?
      redirect_to caixa_path(@caixa), alert: "Há comandas abertas neste caixa (#{pendentes.map { |c| "Mesa #{c.mesa.numero}" }.join(", ")}). Finalize-as antes de fechar o caixa."
      return
    end

    esperado = @caixa.dinheiro_esperado
    @caixa.assign_attributes(
      valor_esperado_dinheiro: esperado,
      valor_contado: fechamento_params[:valor_contado],
      fechamento_user: current_user,
      status: Caixa::FECHADO,
      fechado_em: Time.current
    )
    @caixa.diferenca = @caixa.valor_contado.to_d - esperado if @caixa.valor_contado

    if @caixa.save
      redirect_to caixa_path(@caixa), notice: "Caixa fechado com sucesso."
    else
      render :fechar, status: :unprocessable_content
    end
  end

  private

  def set_caixa
    @caixa = Caixa.includes(:user, :fechamento_user, movimentacao_financeiras: :categoria_financeira).find(params[:id])
  end

  def caixa_params
    params.require(:caixa).permit(:saldo_inicial).tap do |permitted|
      permitted[:saldo_inicial] = normalize_decimal(permitted[:saldo_inicial])
    end
  end

  def fechamento_params
    params.require(:caixa).permit(:valor_contado).tap do |permitted|
      permitted[:valor_contado] = normalize_decimal(permitted[:valor_contado])
    end
  end
end
