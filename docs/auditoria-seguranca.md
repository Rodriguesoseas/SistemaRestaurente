# Auditoria de segurança — Espetaria

## Registro inicial (antes das novas correções desta retomada)

Escopo: Rails, rotas, configuração, dependências e integridade das operações.
Produção ainda não publicada. A análise não equivale a um teste de invasão no
ambiente de hospedagem. Nenhum valor de segredo é reproduzido neste documento.

Baseline anterior registrado: 147 testes / 806 assertions, sem falhas. Brakeman
e advisory DB foram executados antes das últimas mudanças; serão repetidos ao
final. Testes Rails convencionais desabilitam CSRF: exigem cobertura específica.

## CRÍTICO

Nenhuma exploração remota não autenticada classificada como crítica foi
confirmada. Isso não prova ausência de vulnerabilidades.

## ALTO

### A01 — Corrida entre fechamento do caixa e operações vinculadas
- Arquivos/trechos iniciais: `app/controllers/caixas_controller.rb:46-70`,
  `app/models/comanda.rb:41-76`, `app/models/movimentacao_financeira.rb:69-73`.
- Vulnerabilidade: consulta de status/pendências e gravação não compartilham
  bloqueio da linha do caixa. Associações podem estar desatualizadas.
- Cenário: dois operadores enviam lançamento/abertura e fechamento simultâneos.
- Impacto: lançamento em caixa já fechado, conferência incorreta ou caixa com
  comanda pendente.
- Recomendação: transação com bloqueio do caixa em todas as operações,
  leitura fresca e ordem de locks única: caixa → comanda → produto.

### A02 — Corrida entre pagamento e mutação de itens
- Arquivos/trechos: `app/models/item_comanda.rb:5-15,39-53`,
  `app/controllers/itens_controller.rb:4-59`, `app/models/comanda.rb:33-43`.
- Vulnerabilidade: itens não compartilham o lock usado pelo pagamento; status
  aberto pode ter sido carregado antes de outro pedido finalizar a comanda.
- Cenário: alteração/remoção/inclusão simultânea ao pagamento.
- Impacto: itens diferentes da entrada financeira e histórico pago alterado.
- Recomendação: serializar mutações e pagamento sob os mesmos locks, congelar
  snapshots e somar os subtotais já arredondados.

### A03 — Segredo local exposto na saída de uma ferramenta
- Local: execução anterior de `rails credentials:show`, não um arquivo público.
- Vulnerabilidade: o secret_key_base local foi impresso na conversa.
- Cenário: reutilização dessa chave em produção por engano.
- Impacto: compromete a confiança em cookies/assinaturas que dependam da chave.
- Recomendação: rotacionar o segredo exposto; produção deve exigir
  SECRET_KEY_BASE exclusivo e novo, sem fallback para credenciais locais.
  Não imprimir ou copiar a chave para este relatório.

### A04 — Histórico protegido apenas pela ausência de rotas
- Arquivos: `app/models/movimentacao_financeira.rb`,
  `app/models/movimentacao_estoque.rb`, `app/models/caixa.rb`, `app/models/comanda.rb`.
- Vulnerabilidade: updates/destroys ordinários dos models não têm proteção
  uniforme; criar movimentação de estoque diretamente não atualiza o saldo.
- Cenário: console, futura rotina interna ou nova rota usa os models diretamente.
- Impacto: perda de histórico e divergência financeira/estoque.
- Recomendação: operações append-only no ciclo normal de persistência e saldo
  atualizado atomicamente também ao criar pelo model. SQL direto é privilégio
  administrativo e permanece fora dessas proteções de aplicação.

## MÉDIO

### M01 — CSP incompatível com Importmap
- Arquivo: `config/initializers/content_security_policy.rb:3-9`.
- Cenário: `script-src 'self'` não permite o importmap/bootstrap inline do Rails.
- Impacto: Turbo/Stimulus/gráficos deixam de funcionar após a proteção ser ligada.
- Recomendação: nonces por resposta, sem unsafe-inline para scripts; validar
  navegador real, headers e gráficos com CSRF ligado.

### M02 — Datas, decimais e totais sem limites completos
- Arquivos: `app/models/filtro_periodo.rb:105-120`, validações numéricas de
  Caixa, Produto, ItemComanda, MovimentacaoFinanceira e MovimentacaoEstoque.
- Cenário: números enormes, NaN/Infinity, submilésimos, string malformada ou
  intervalo de anos arbitrariamente grande recebido pela URL/formulário.
- Impacto: 500, cálculo inconsistente ou consumo excessivo de recursos.
- Recomendação: validar tipo/formato, escala e limites antes de gravar/iterar;
  não confiar apenas em min/max do HTML ou conversão permissiva de strings.

### M03 — Confirmação de preço pode ser contornada
- Arquivo: `app/controllers/itens_controller.rb:72-80`.
- Cenário: enviar confirmar_preco=1 ou omitir preco_exibido; preço muda novamente
  enquanto a confirmação está aberta.
- Impacto: não permite escolher preço arbitrário, mas cobra novo preço sem
  confirmação vinculada àquele valor.
- Recomendação: comparar sempre o preço confirmado com o produto bloqueado.

### M04 — Sem limitação por IP e sem perfis de acesso
- Arquivos: `app/models/user.rb`, `config/initializers/devise.rb`,
  `app/controllers/application_controller.rb:2`.
- Evidência: lockable e timeoutable já introduzidos; não há Pundit/policies/roles
  nem rate limit distribuído por origem.
- Cenário: tentativas distribuídas/bloqueio proposital de conta; qualquer usuário
  criado pelo administrador possui as mesmas permissões operacionais.
- Impacto: indisponibilidade do login e ausência de separação de funções.
- Recomendação: limitar tráfego no proxy antes de publicar; definir matriz de
  perfis se houver funcionários restritos. No escopo atual, conta autenticada
  representa operador confiável do mesmo estabelecimento (não multiempresa).

### M05 — Produção depende de variáveis/proxy ainda não verificados
- Arquivos: `config/environments/production.rb:25-28,59-62`, `config/database.yml:19-23`.
- Cenário: RAILS_HOST ausente desativa allowlist; DATABASE_URL incorreta ou sem
  TLS; assume_ssl fora de um proxy confiável.
- Impacto: host spoofing, configuração inválida e transporte inadequado.
- Recomendação: falhar claramente sem variáveis obrigatórias; testar TLS do
  PostgreSQL, redirecionamento HTTPS e headers no ambiente publicado.

### M06 — CSV: fórmulas precedidas por controle/espaço
- Arquivo: `app/controllers/relatorios_controller.rb:123-126`.
- Cenário: célula começa com tab ou espaços seguidos de =, +, -, @.
- Impacto: execução de fórmula quando a planilha interpreta o conteúdo.
- Recomendação: neutralizar também os prefixos de whitespace/controle, testar
  com parser CSV; confirmar comportamento no Excel/LibreOffice manualmente.

## BAIXO

### B01 — Listagens/exportações sem paginação
- Arquivos: controllers de relatórios e listagens.
- Cenário: usuário autenticado solicita todo o histórico repetidamente.
- Impacto: consumo de memória/tempo cresce com volume; não é SQL Injection.
- Recomendação: paginação e exportação em lotes conforme volume real.

## INFORMATIVO

- `force_ssl = true` e `consider_all_requests_local = false` já configurados.
- Todas as rotas operacionais herdam authenticate_user!. `/entrar` e `/up`
  são públicos por finalidade; não existem cadastro público nem CRUD de users.
- Item é procurado dentro de `@comanda.item_comandas`, restringindo ID cruzado.
- Índices únicos parciais existem para caixa aberto e mesa/comanda aberta;
  índice único de comanda_id impede duas entradas da mesma comanda.
- Nenhum html_safe/raw de entrada do usuário encontrado. ERB escapa os dados.
- SQL manual dos relatórios usa constantes de formato/fuso, não parâmetros
  interpolados. Arel.sql não sanitiza conteúdo e não deve receber params.
- `config/master.key`, `.env.local`, `.env.test.local` e `.local/` são ignorados
  pelo Git; o repositório não tem commits nem arquivos rastreados no baseline.
- RAILS_MASTER_KEY não substitui SECRET_KEY_BASE e não deve ser versionada.
- Filtro de logs cobre senha/e-mail/token/chaves. Não imprimir credentials:show,
  DATABASE_URL ou conteúdo dos arquivos .env em comandos de diagnóstico.
- Não há services/policies adicionais: regras atualmente residem nos models
  e controllers inspecionados.

## Validação final — concluída

Correções aplicadas e revalidadas em 02/10/2026:

- **A01/A02 (locks):** ordem única caixa → comanda → produto em `pagar!`;
  mutações de itens sob lock real da comanda (+ produto); removido o bypass
  `Rails.env.test?`. Cobertura: `test/models/comanda_concorrencia_test.rb`
  (8 threads adicionando itens sem perda; pagamento duplo simultâneo gera
  exatamente 1 entrada).
- **Confirmação de preço:** `confirmar_preco` virou atributo do item e é
  respeitado também no callback do model (antes, a segunda checagem ignorava
  a confirmação e abortava o save).
- **Sessão:** removido o filtro manual duplicado; expiração delegada ao
  Devise `:timeoutable`. Cookie com teto absoluto de 8h para que a mensagem
  de expiração seja alcançável (com 30 min nos dois, o cookie morria antes
  e o usuário via só a mensagem genérica).
- **Limpeza:** removidos logs `DEBUG`, testes de debug, script avulso e
  override de logger do ambiente de teste; `normalize_decimal` centralizado;
  5 scopes/métodos mortos removidos; botões em 44px; fallback textual no gráfico.
- **A03:** script `script/rotate_local_secret.rb` criado; **rotação ainda não
  executada** — fazer antes de qualquer uso real + `SECRET_KEY_BASE` novo
  e exclusivo em produção (residual).

Resultados: `rails test` 160 runs / 845 assertions / 0 falhas;
`test:system` 15 runs / 261 assertions / 0 falhas; `rubocop` 93 arquivos
limpo; `brakeman` 0 warnings; `bundler-audit` limpo.

Riscos residuais e verificações manuais exigidas no deploy estão na resposta
de entrega (não declarar o sistema 100% seguro).
