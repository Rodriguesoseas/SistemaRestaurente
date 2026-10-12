class MesasController < ApplicationController
  before_action :set_mesa, only: [ :show, :edit, :update ]

  def index
    @mesas = Mesa.includes(:comanda_aberta).ordenadas
  end

  def show
    @comandas = @mesa.comandas.includes(:abertura_user, :pagamento_user).recentes
  end

  def new
    @mesa = Mesa.new(ativo: true)
  end

  def create
    @mesa = Mesa.new(mesa_params)

    if @mesa.save
      redirect_to mesas_path, notice: "Mesa #{@mesa.numero} cadastrada com sucesso."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @mesa.update(mesa_params)
      redirect_to mesas_path, notice: "Mesa #{@mesa.numero} atualizada com sucesso."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_mesa
    @mesa = Mesa.find(params[:id])
  end

  def mesa_params
    params.require(:mesa).permit(:numero, :nome, :ativo)
  end
end
