# Espetaria

Sistema web administrativo para uma pequena espetaria. Monólito Rails, com interface
em português e prioridade para uso no celular.

## Estado do projeto

**Fase 1 — Estrutura e acesso.** Login/logout, usuário administrador, Dashboard inicial,
layout responsivo, PostgreSQL, localização brasileira e testes.

**Fase 2 — Caixa.** Abertura com saldo inicial, caixa atual com resumo, fechamento
com conferência de dinheiro (esperado, contado, diferença), histórico e detalhes.
Apenas um caixa aberto por vez, garantido por validação e índice único parcial no
PostgreSQL. Caixa fechado não pode ser alterado. Entradas/saídas ainda zeradas:
os totais serão ligados ao módulo financeiro na Fase 3.

Os cards do Dashboard continuam como estados vazios. Mesas, estoque
e relatórios aparecem como **Em breve**. A sequência e as regras aprovadas estão em
[docs/escopo.md](docs/escopo.md). A próxima fase exige autorização explícita.

**Fase 3 — Financeiro.** Categorias de entrada (Venda, Outros) e de saída
(Mercadoria, Carnes, Bebidas, Carvão, Gás, Energia, Fornecedor, Manutenção,
Funcionários, Outros) com seeds idempotentes. Lançamentos vinculados ao caixa
aberto e ao responsável da sessão, com valor decimal positivo, categoria
compatível com o tipo e forma de pagamento (Dinheiro, Pix, Débito, Crédito,
Outro; obrigatória nas entradas, "Não informada" nas saídas). Listagem com
filtros por tipo, categoria e pagamento, com totais e resultado do filtro.
Sem edição nem exclusão de lançamentos. Os totais do caixa (entradas, saídas,
resultado, dinheiro esperado e entradas por pagamento) são calculados das
movimentações; somente dinheiro compõe a conferência física.

**Fase 4 — Produtos + mesas/comandas.** Categorias de produtos com seeds
(Carnes, Espetinhos, Bebidas, Carvão, Descartáveis, Temperos, Outros) e
produtos com preço de venda, disponibilidade e unidades (inclusive kg/litro
fracionados); sem exclusão, apenas inativação. Mesas com número único e
ocupação pela comanda aberta. Comandas vinculadas ao caixa da abertura, com
itens (snapshot de nome/preço, subtotal e total no servidor), alteração de
quantidade e remoção enquanto abertas. Pagamento atômico cria uma única
entrada na categoria Venda, vinculada à comanda, e libera a mesa; comanda de
total zero não pode ser paga. Fechamento do caixa bloqueado com comandas
pendentes (lista as mesas). Estoque permanece zerado até a Fase 5: pedidos
não baixam saldo.

**Fase 5 — Estoque manual.** Entradas e saídas manuais com quantidade
decimal positiva, motivo em lista fixa por tipo (Entrada: Compra, Ajuste,
Devolução, Outros; Saída: Consumo interno, Perda, Ajuste, Outros),
observação e responsável da sessão. Saldo atualizado atomicamente com
bloqueio de linha; saída maior que o saldo é recusada e o estoque nunca
fica negativo. Status por produto (Sem estoque, Estoque baixo, Normal),
histórico por produto e card "Estoque baixo" no Dashboard contando produtos
ativos com saldo no mínimo ou zerados.

**Fase 6 — Dashboard real.** Indicadores de entradas, saídas e resultado no
período, caixa atual, mesas ocupadas, estoque baixo e últimas movimentações.
Filtro global por período (Hoje, Semana de segunda a domingo, Mês,
Trimestre, Semestre, Ano e Personalizado) via parâmetros na URL, com
navegação entre períodos anteriores, validação de datas e fallback para hoje
com aviso. Datas respeitadas em America/Fortaleza; totais calculados no
PostgreSQL. Caixa, mesas e estoque mostram sempre o estado atual.

**Fase 7 — Gráficos, relatórios e CSV.** Página `/relatorios` com o filtro
global de período, resumo (entradas, saídas, resultado, caixas abertos e
média diária sobre os dias corridos), gráficos de entradas/saídas e
resultado (Chartkick + Chart.js vendored, sem CDN) com granularidade
automática — dia para Hoje/Semana/Mês, mês para Trimestre/Semestre/Ano,
personalizado até 31 dias por dia, 32–366 por mês e acima por ano — e
intervalos vazios zerados. Agregações em PostgreSQL com datas em
America/Fortaleza. Totais por pagamento, despesas por categoria e
exportações CSV de movimentações, caixas, produtos e comandas (financeiras
respeitando o período).

**Fase 8 — Interface.** Revisão de todas as telas em celular (390px),
tablet (768px) e desktop (1440px), sem rolagem horizontal em nenhuma
página (cobertura automatizada em `test/system/responsivo_test.rb`).
Tabelas com rolagem interna, formulários com rótulos e erros acessíveis,
confirmações em ações irreversíveis (abrir comanda, registrar
movimentações, fechar caixa, pagar, remover pedido), estados vazios em
todas as listagens e alvos de toque ampliados nos links de ação.

**Fase 9 — Revisão.** Auditoria de segurança (Brakeman limpo, autenticação
em todos os controllers), validações espelhadas no PostgreSQL (unicidade
case-insensitive e 12 check constraints de valores e quantidades),
recuperação de abertura concorrente de caixa, eager loading nas telas de
caixa e comandas, neutralização de fórmulas nos CSVs e agrupamentos sempre
no fuso America/Fortaleza.

## Stack

- Ruby 3.4.10 / Rails 8.1.4.
- PostgreSQL (18.6 no ambiente Windows preparado).
- ERB, Importmap, Turbo e Stimulus.
- Tailwind CSS 4 via `tailwindcss-rails`, sem frontend separado.
- Devise 5, somente autenticação por e-mail/senha.
- Minitest, Capybara e Selenium.

Locale `pt-BR`, timezone `America/Fortaleza`, persistência de horários em UTC.
Datas `DD/MM/AAAA`, horas `HH:MM` e valores `R$ 1.250,00`.

## Instalação

Execute os comandos na raiz do projeto. No PowerShell, use `bundle exec rails` ou
`ruby bin/rails`; os exemplos não dependem de scripts shell Unix.

```powershell
bundle install
```

### PostgreSQL local no Windows (ambiente preparado)

A instalação local usa os binários oficiais da EDB, dentro de `.local/pgsql`.
O servidor aceita conexões somente em `127.0.0.1:5433`, com autenticação SCRAM.
Não exige serviço Windows nem privilégios de administrador.

```powershell
bundle exec ruby script/local_database.rb start
bundle exec ruby script/local_database.rb status
```

Para parar, depois de encerrar a aplicação:

```powershell
bundle exec ruby script/local_database.rb stop
```

O comando `setup` **já foi executado neste ambiente**. Em uma instalação nova:

1. Baixe os binários Windows x64 em https://www.enterprisedb.com/download-postgresql-binaries.
2. Extraia `pgsql/bin`, `pgsql/lib` e `pgsql/share` para `.local/pgsql`.
3. Execute `bundle exec ruby script/local_database.rb setup` uma única vez.

O script cria um cluster local e um usuário `espetaria` com permissão de criação de
bancos, sem superusuário. Gera `.env.local` e `.env.test.local`, com credenciais
aleatórias, e guarda a senha de manutenção em `.local/postgres-admin-password`.
Esses arquivos, os binários e os dados são ignorados pelo Git. Não remova `.local`
para atualizar o código: ela contém os dados locais.

### PostgreSQL já instalado

Crie um usuário PostgreSQL de desenvolvimento com `LOGIN` e `CREATEDB`.
Copie `.env.example` para `.env.local` pelo editor e preencha as variáveis.
Crie também `.env.test.local` com `PGHOST`, `PGPORT`, `PGUSER` e `PGPASSWORD`:
o Dotenv não carrega `.env.local` nos testes.

Os bancos são separados:

- Desenvolvimento: `espetaria_development`.
- Testes: `espetaria_test`.

`TEST_DATABASE_URL`, quando definida, substitui somente a conexão de testes.
O ambiente de testes usa uma URL explícita para não herdar `DATABASE_URL`.
Essa variável deve apontar exclusivamente para um banco descartável de testes.

## Variáveis de ambiente

- `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`: conexão local.
- `ADMIN_EMAIL`, `ADMIN_PASSWORD`: criação inicial do administrador de desenvolvimento.
- `TEST_DATABASE_URL`: conexão alternativa exclusiva para testes.
- `DATABASE_URL`: conexão de produção.
- `SECRET_KEY_BASE`: segredo de sessão em produção, gerado com `bundle exec rails secret`.
- `RAILS_MASTER_KEY`: necessário se forem utilizadas credenciais criptografadas Rails.

Nunca versione valores reais de credenciais, tokens ou senhas. O `.env.example`
contém apenas nomes de configuração e campos vazios.

## Preparar banco e administrador

Com PostgreSQL iniciado e variáveis configuradas:

```powershell
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rails db:migrate RAILS_ENV=test
bundle exec rails tailwindcss:build
```

Ou execute `ruby bin/setup --skip-server`, que realiza essa preparação.

O seed funciona somente em desenvolvimento. Ele cria o administrador se necessário
e preserva a senha de um usuário existente. Não existe senha padrão compartilhada.

**Neste ambiente**, o e-mail é `admin@espetaria.local`. Consulte `ADMIN_PASSWORD` no
arquivo local `.env.local` pelo editor para obter a senha gerada. Não publique esse arquivo.

### Criar usuário pelo console

Defina `ADMIN_EMAIL` e `ADMIN_PASSWORD` no ambiente e execute:

```powershell
bundle exec rails console
```

No console:

```ruby
User.create!(email: ENV.fetch("ADMIN_EMAIL"), password: ENV.fetch("ADMIN_PASSWORD"))
```

A senha deve ter no mínimo oito caracteres. Não há cadastro público, recuperação
por e-mail ou interface de gestão de usuários nesta fase.

## Executar

Primeiro terminal:

```powershell
bundle exec ruby script/local_database.rb start
bundle exec rails tailwindcss:build
bundle exec rails server -b 127.0.0.1 -p 3000
```

Abra **http://127.0.0.1:3000**. O visitante é direcionado para `/entrar`.

Durante alterações de estilo, mantenha um segundo terminal aberto:

```powershell
bundle exec rails tailwindcss:watch
```

Pare o servidor e o watcher com `Ctrl+C`. Em Linux/macOS, `bin/dev` também pode
iniciar Rails e o watcher via Foreman.

## Testes e verificações

```powershell
bundle exec rails db:migrate RAILS_ENV=test
bundle exec rails test
bundle exec rails test:system
bundle exec rails zeitwerk:check
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bundle exec ruby bin/importmap audit
```

Os testes de sistema usam Edge headless no Windows e Chrome headless no Linux.
O Selenium Manager pode precisar de internet na primeira execução para obter o
driver. Os testes verificam login, erro de senha, logout, menu mobile, tecla Escape
e ausência de rolagem horizontal em viewports de 390, 768 e 1440 pixels.
Capturas ficam em `tmp/screenshots`, ignorado pelo Git.

Testes de modelo/integração cobrem unicidade de e-mail no banco, autenticação,
ausência de cadastro público, seed idempotente e formatação brasileira.

O workflow `.github/workflows/ci.yml` executa verificações e testes com PostgreSQL
no GitHub quando o repositório for publicado. A execução remota depende dessa publicação.

Logs Rails: `log/development.log` e `log/test.log`. Log PostgreSQL local:
`.local/postgres.log`.

## Deploy planejado

O deploy será realizado somente na Fase 10. A intenção é usar Render e Neon,
após confirmar a disponibilidade dos planos gratuitos. A aplicação e o banco
ficarão em serviços separados.

Naquela fase serão configurados `DATABASE_URL`, `SECRET_KEY_BASE`, HTTPS, domínio,
build (`bundle install` e `bundle exec rails assets:precompile`), migrations
(`bundle exec rails db:migrate`) e administrador de produção pelo console.
O seed de desenvolvimento é ignorado em produção.

Não há deploy, remote Git, commit ou publicação realizados pela Fase 1.
