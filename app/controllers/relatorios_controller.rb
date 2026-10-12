require "csv"

class RelatoriosController < ApplicationController
  before_action :carregar_filtro

  def index
    @relatorio = RelatorioFinanceiro.new(@filtro)
  end

  def movimentacoes
    movimentacoes = MovimentacaoFinanceira
      .where(ocorrido_em: @filtro.intervalo)
      .includes(:categoria_financeira, :user)
      .recentes
    responder_csv("movimentacoes", %w[Data Descrição Tipo Categoria Pagamento Valor Responsável]) do |csv|
      movimentacoes.each do |movimentacao|
        csv << [
          I18n.l(movimentacao.ocorrido_em),
          texto_csv(movimentacao.descricao),
          movimentacao.entrada? ? "Entrada" : "Saída",
          texto_csv(movimentacao.categoria_financeira.nome),
          movimentacao.forma_pagamento_rotulo,
          moeda_csv(movimentacao.valor),
          texto_csv(movimentacao.user.email)
        ]
      end
    end
  end

  def caixas
    caixas = Caixa.where(aberto_em: @filtro.intervalo).includes(:user, :fechamento_user).recentes
    responder_csv("caixas", [ "Abertura", "Fechamento", "Responsável abertura", "Responsável fechamento",
                              "Saldo inicial", "Entradas", "Saídas", "Resultado",
                              "Esperado", "Contado", "Diferença", "Status" ]) do |csv|
      caixas.each do |caixa|
        csv << [
          I18n.l(caixa.aberto_em),
          caixa.fechado_em ? I18n.l(caixa.fechado_em) : "",
          texto_csv(caixa.user.email),
          caixa.fechamento_user ? texto_csv(caixa.fechamento_user.email) : "",
          moeda_csv(caixa.saldo_inicial),
          moeda_csv(caixa.entradas),
          moeda_csv(caixa.saidas),
          moeda_csv(caixa.resultado),
          caixa.valor_esperado_dinheiro ? moeda_csv(caixa.valor_esperado_dinheiro) : "",
          caixa.valor_contado ? moeda_csv(caixa.valor_contado) : "",
          caixa.diferenca ? moeda_csv(caixa.diferenca) : "",
          caixa.aberto? ? "Aberto" : "Fechado"
        ]
      end
    end
  end

  def produtos
    produtos = Produto.includes(:categoria_produto).ordenados
    responder_csv("produtos", [ "Nome", "Categoria", "Unidade", "Preço venda", "Preço custo",
                                "Disponível", "Ativo", "Saldo", "Mínimo" ]) do |csv|
      produtos.each do |produto|
        csv << [
          texto_csv(produto.nome),
          texto_csv(produto.categoria_produto.nome),
          produto.unidade_rotulo,
          produto.preco_venda ? moeda_csv(produto.preco_venda) : "",
          produto.preco_custo ? moeda_csv(produto.preco_custo) : "",
          produto.disponivel_venda? ? "Sim" : "Não",
          produto.ativo? ? "Sim" : "Não",
          quantidade_csv(produto.quantidade_atual),
          quantidade_csv(produto.estoque_minimo)
        ]
      end
    end
  end

  def comandas
    comandas = Comanda.where(aberta_em: @filtro.intervalo).includes(:mesa, :abertura_user, :pagamento_user).recentes
    responder_csv("comandas", [ "Mesa", "Abertura", "Fechamento", "Responsável abertura",
                                "Responsável pagamento", "Total", "Pagamento", "Status" ]) do |csv|
      comandas.each do |comanda|
        csv << [
          comanda.mesa.numero,
          I18n.l(comanda.aberta_em),
          comanda.fechada_em ? I18n.l(comanda.fechada_em) : "",
          comanda.abertura_user ? texto_csv(comanda.abertura_user.email) : "",
          comanda.pagamento_user ? texto_csv(comanda.pagamento_user.email) : "",
          moeda_csv(comanda.valor_total),
          comanda.forma_pagamento ? MovimentacaoFinanceira::ROTULOS_FORMA_PAGAMENTO.fetch(comanda.forma_pagamento) : "",
          comanda.aberta? ? "Aberta" : "Fechada"
        ]
      end
    end
  end

  private

  def carregar_filtro
    @filtro = FiltroPeriodo.de_params(params)
    flash.now[:alert] = @filtro.aviso if @filtro.aviso && action_name == "index"
  end

  def responder_csv(nome_base, cabecalho)
    respond_to do |format|
      format.csv do
        conteudo = "\uFEFF" + CSV.generate(col_sep: ";") do |csv|
          csv << cabecalho
          yield csv
        end
        send_data conteudo, filename: "#{nome_base}-#{periodo_arquivo}.csv", type: "text/csv; charset=utf-8"
      end
      format.html { redirect_to relatorios_path(@filtro.parametros_url) }
    end
  end

  def periodo_arquivo
    inicio = @filtro.intervalo.begin.to_date.iso8601
    fim = @filtro.intervalo.end.to_date.iso8601
    "#{inicio}_a_#{fim}"
  end

  def moeda_csv(valor)
    format("%.2f", valor).tr(".", ",")
  end

  def texto_csv(valor)
    # Neutraliza fórmulas de planilha em textos livres e e-mails.
    texto = valor.to_s
    texto.match?(/\A(?:[\t\r\n]|[[:space:]]*[=+\-@])/) ? "'#{texto}" : texto
  end

  def quantidade_csv(valor)
    format("%.3f", valor).tr(".", ",")
  end
end
