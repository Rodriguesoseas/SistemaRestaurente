# Plano unificado — Sistema web para espetaria

Este documento consolida o plano e as regras aprovadas. O projeto começou do zero.
Implementar uma fase por vez e parar para autorização da próxima.

## Objetivo e stack

Controle interno simples de uma espetaria: entradas/saídas, caixa, mesas/comandas,
produtos, estoque manual, Dashboard, relatórios e CSV. Interface mobile-first para
uso por pessoas sem conhecimento técnico.

Rails + PostgreSQL + ERB + Hotwire/Turbo/Stimulus + Tailwind + Devise. Monólito sem
frontend/API separados. Gráficos com Chartkick/Chart.js na fase correspondente.
Git/GitHub. Render/Neon planejados, condicionados à disponibilidade no deploy.

Português brasileiro, timezone America/Fortaleza, datas DD/MM/AAAA, horas HH:MM,
moeda R$ 1.250,00. Horários persistidos em UTC. Dinheiro em decimal, nunca float.

## Regras aprovadas

### Autenticação e responsáveis

- Login por e-mail/senha, sem cadastro público. Administrador por seed ou console.
- Registrar responsáveis distintos por abertura e fechamento do caixa, abertura
  e pagamento da comanda, movimentação financeira e movimentação de estoque.
- Responsáveis vêm da sessão autenticada, não de campo livre do formulário.

### Caixa e financeiro

- Apenas um caixa aberto por vez, com proteção também no PostgreSQL.
- Caixa aberto obrigatório para abrir comanda, adicionar/alterar pedidos e pagar.
- Comanda vinculada ao caixa aberto na sua abertura.
- **Bloquear fechamento do caixa enquanto houver comandas abertas vinculadas.**
  Mostrar as mesas pendentes e solicitar sua finalização.
- Caixa fechado não recebe novas movimentações nem pode ser fechado novamente.
- Saldo inicial e valor contado não negativos.
- Resultado = entradas - saídas; não chamar automaticamente de lucro.
- Saldo consolidado = saldo inicial + entradas - saídas.
- Dinheiro esperado = saldo inicial + entradas em dinheiro - saídas em dinheiro.
- Diferença = contado - esperado. Pix/cartão não entram na conferência física.
- Salvar esperado, contado, diferença, horário e responsável pelo fechamento.
- Movimentação: caixa, usuário, tipo, descrição, valor decimal(10,2), categoria,
  forma de pagamento, data e comanda de origem quando houver.
- Valor maior que zero; categoria compatível com entrada/saída.
- Pagamentos: Dinheiro, Pix, Débito, Crédito, Outro. Obrigatório nas entradas;
  opcional em determinadas despesas. Ausência é "Não informada", não dinheiro.
- Sem edição silenciosa ou exclusão livre dos registros financeiros.
- Histórico e detalhes de caixas: abertura/fechamento, responsáveis, saldo inicial,
  entradas, saídas, resultado, pagamentos, contado, diferença e status.

Categorias financeiras de entrada: Venda, Outros.
Saída: Mercadoria, Carnes, Bebidas, Carvão, Gás, Energia, Fornecedor, Manutenção,
Funcionários e Outros.

### Produtos e itens de venda

- Produto: nome, categoria_produto_id, quantidade_atual, unidade, estoque_minimo,
  ativo, preco_custo opcional, preco_venda e disponivel_venda.
- preco_venda decimal(10,2); obrigatório quando disponivel_venda = true.
- Preços informados >= 0. Produto exclusivo de estoque pode ter preço vazio.
- disponivel_venda boolean com default true e null false.
- Quantidades em decimal para suportar kg/litros fracionados.
- Cadastro e listagem exibem preço de venda e disponibilidade, além dos campos de
  estoque. Saldo atual é alterado por movimentações para preservar histórico.
- Somente produtos ativos e disponíveis para venda entram em novos pedidos.
- Disponibilidade para venda não depende automaticamente do saldo de estoque.
- Seleção preenche nome e preço; funcionário informa quantidade e observação.
- Backend consulta produto e valida novamente sua disponibilidade. Não aceita
  preço, descrição ou subtotal arbitrários enviados pelo navegador.
- Se o preço mudar entre seleção e envio, apresentar o novo preço para confirmação.
- Item guarda descrição e valor_unitario do momento da inclusão (snapshot).
- Alterar quantidade usa o valor_unitario já salvo. Novos itens usam preço vigente.
- Produtos inativos/fora de venda permanecem identificados no histórico.
- Produto é inativado; evitar exclusão que comprometa os itens antigos.
- Produtos internos, como carvão, podem ter disponivel_venda = false.

Categorias: Carnes, Espetinhos, Bebidas, Carvão, Descartáveis, Temperos e Outros.
Unidades: unidade, kg, litro, pacote, caixa, garrafa e outro.
Seeds futuros de desenvolvimento: espeto de carne R$ 10,00, frango R$ 9,00,
cerveja R$ 8,00, refrigerante R$ 6,00 e carvão indisponível para venda.

### Mesas e comandas

- Mesa: número único, nome opcional, ativo. Livre/ocupada é determinado pela
  existência de comanda aberta, sem duplicar fonte de verdade.
- Uma única comanda aberta por mesa, com índice único parcial.
- Comanda: mesa, usuário de abertura, usuário de pagamento, caixa, status,
  aberta_em, fechada_em, valor_total e forma_pagamento.
- Status: aberta, fechada, cancelada. Fluxo operacional de cancelamento é futuro.
- Item: comanda, produto, descrição, quantidade > 0, valor_unitario >= 0,
  subtotal e observação opcional. Novos itens exigem produto nesta versão.
- subtotal = quantidade × valor_unitario; total = soma dos subtotais.
- Totais calculados pelo servidor, sem digitação manual ou alteração de preço.
- Enquanto aberta: adicionar, alterar quantidade e remover itens.
- Fechada: itens, quantidades e valores congelados.
- Pagamento atômico: validar caixa/comanda, recalcular total, criar uma entrada
  na categoria Venda, vincular à comanda/caixa, fechar e liberar a mesa.
- Pagamento único: transação, bloqueios e referência única impedem duplicações
  por duplo clique/requisições simultâneas. Interface não solicita lançamento manual.
- Sem caixa: "Abra o caixa antes de finalizar esta comanda." Preservar os itens.
- Comanda de total zero não pode ser finalizada como venda, porque a entrada
  financeira exige valor positivo. Itens gratuitos continuam permitidos.
- Histórico/detalhes: mesa, datas/horas, responsáveis, itens, quantidades, preços,
  subtotal, total, forma de pagamento e status.

### Estoque

- **Não baixar estoque ao adicionar, editar, remover ou pagar itens de comanda.**
- MovimentacaoEstoque: produto, usuário, entrada/saída, quantidade > 0, motivo,
  observação e data/hora.
- Operação e saldo atualizados atomicamente, com bloqueio contra concorrência.
- Nunca permitir estoque negativo; saldo inicial zero no cadastro.
- Zero: Sem estoque. Positivo <= mínimo: Estoque baixo. Acima: Normal.
- Dashboard conta produtos ativos com quantidade <= estoque mínimo.
- Histórico por produto com tipo, quantidade, motivo, responsável e data.

### Relatórios e Dashboard

- Indicadores: entradas, saídas, resultado, caixa atual, mesas ocupadas, estoque
  baixo e últimas movimentações.
- Filtro financeiro: Hoje, Semana, Mês, Trimestre, Semestre, Ano, Personalizado.
- Semana de segunda a domingo; trimestre/semestre de calendário. Permitir
  períodos anteriores e parâmetros na URL. Validar datas e intervalo.
- Datas respeitam America/Fortaleza. Caixa, mesas e estoque mostram estado atual;
  período altera os dados financeiros, gráfico e lista de movimentações.
- Gráfico: Entradas/Saídas/Resultado; hoje visão diária; semana/mês por dia;
  trimestre/semestre/ano por mês. Personalizado até 31 dias por dia, 32–366 por
  mês, acima de 366 por ano. Intervalos vazios devem aparecer com zero.
- Totais e agrupamentos em PostgreSQL (SUM, COUNT, GROUP BY), evitando carregar
  todo o histórico em memória.
- Relatórios: entradas, saídas, resultado, quantidade de caixas abertos no período,
  média diária do resultado, totais por pagamento e despesas por categoria.
- Média diária = resultado / dias corridos do filtro, incluindo dias sem movimento.
- Somente movimentações válidas entram nos totais, com regra compartilhada por
  todos os períodos. Registros cancelados são excluídos dos totais.
- Cancelamento/ajuste operacional será solicitado posteriormente e deverá guardar
  responsável, data e motivo, preservando a conferência dos caixas fechados.
- CSV: movimentações financeiras, caixas e produtos; comandas se simples.
  Exportações financeiras respeitam os filtros.

## Fases de implementação

1. **Estrutura**: Rails/PostgreSQL, Devise/User/login/logout, Tailwind/Hotwire,
   layout/menu responsivo, Dashboard inicial, pt-BR/Fortaleza, seed de administrador,
   documentação e testes básicos. Criar apenas a tabela users. Parar.
2. **Caixa** (concluída): abertura, caixa único (validação + índice único parcial),
   atual, fechamento, conferência (esperado/contado/diferença), histórico e
   detalhes. Caixa fechado imutável. Entradas/saídas zeradas; integrar totais na
   Fase 3. Testada com navegador real, inclusive com proteção CSRF ativada. Parar.
3. **Financeiro**: categorias, entradas/saídas, pagamentos, caixa, validações,
   listagem, filtros básicos, totais e seeds de categorias. Testar. Parar.
4. **Produtos + mesas/comandas**: primeiro categorias/produtos com preço e
   disponibilidade; depois mesas, comandas e itens, seleção/preenchimento,
   cálculo, pagamento automático, histórico e detalhes. Bloquear fechamento de
   caixa com comandas pendentes. Estoque fica zero até Fase 5. Testar fluxo e
   concorrência, preços históricos e ausência de baixa automática. Parar.
5. **Estoque manual**: entrada/saída, saldo, mínimo, alertas, histórico e bloqueio
   de saldo negativo. Testar quantidades fracionadas/concorrência. Parar.
6. **Dashboard real**: indicadores, últimas movimentações e filtro global
   compartilhado. Testar datas, períodos anteriores e timezone. Parar.
7. **Gráficos/relatórios/CSV**: granularidade, períodos vazios, pagamento,
   categorias e média diária. Testar viradas de ano/mês e ano bissexto. Parar.
8. **Interface**: revisar mobile/tablet/desktop, formulários, mesas, comandas,
   cards, tabelas, estados vazios, confirmações, erros e acessibilidade. Parar.
9. **Revisão**: segurança, validações, relacionamentos, índices/constraints,
   cálculos, transações/concorrência, consultas, histórico, timezone e testes. Parar.
10. **Produção**: GitHub, banco, variáveis, build/migrations, administrador,
    mesas iniciais, deploy, HTTPS, logs e testes. Seeds demonstrativos somente
    em desenvolvimento. Parar após entrega documentada.

### Teste final integrado

Login → abrir caixa → abrir Mesa 1 → adicionar pedidos → adicionar outro pedido →
alterar quantidade → verificar total → pagar via Pix → verificar entrada única e
mesa livre → saída financeira → fechar caixa → histórico de caixa/comanda →
cadastrar produto → entrada/saída de estoque → Dashboard → filtros semana,
trimestre, semestre, ano e personalizado → gráfico/valores → CSV → celular e
desktop → logout. Verificar também bloqueio de caixa com comanda pendente.

## Procedimento de trabalho

Antes de cada fase: consultar este documento, analisar o código existente,
identificar dependências e informar resumidamente as alterações. Implementar
somente a fase autorizada. Executar migrations e testes; iniciar a aplicação,
inspecionar logs e corrigir os erros. Atualizar documentação. Entregar arquivos,
migrations, gems, funcionalidades, decisões, comandos e resultados de testes.
Não avançar automaticamente. Não versionar segredos.

## Fora do escopo

NF-e/NFC-e/SEFAZ, iFood, delivery/cardápio público, WhatsApp, impressão automática,
maquininha, integração bancária, folha, contabilidade, multiempresa, SaaS,
assinaturas/planos, descontos/preço manual e baixa automática de estoque.
