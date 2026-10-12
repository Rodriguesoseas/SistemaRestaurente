# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_02_220001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "caixas", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "fechamento_user_id"
    t.decimal "saldo_inicial", precision: 10, scale: 2, null: false
    t.string "status", default: "aberto", null: false
    t.datetime "aberto_em", null: false
    t.datetime "fechado_em"
    t.decimal "valor_esperado_dinheiro", precision: 10, scale: 2
    t.decimal "valor_contado", precision: 10, scale: 2
    t.decimal "diferenca", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aberto_em"], name: "index_caixas_on_aberto_em"
    t.index ["fechamento_user_id"], name: "index_caixas_on_fechamento_user_id"
    t.index ["status"], name: "index_caixas_on_status_aberto", unique: true, where: "((status)::text = 'aberto'::text)"
    t.index ["user_id"], name: "index_caixas_on_user_id"
    t.check_constraint "saldo_inicial >= 0::numeric", name: "caixas_saldo_inicial_nao_negativo"
  end

  create_table "categoria_financeiras", force: :cascade do |t|
    t.string "nome", null: false
    t.string "tipo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "tipo, lower((nome)::text)", name: "index_categoria_financeiras_on_tipo_and_lower_nome", unique: true
  end

  create_table "categoria_produtos", force: :cascade do |t|
    t.string "nome", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "index_categoria_produtos_on_lower_nome", unique: true
  end

  create_table "comandas", force: :cascade do |t|
    t.bigint "mesa_id", null: false
    t.bigint "abertura_user_id", null: false
    t.bigint "pagamento_user_id"
    t.bigint "caixa_id", null: false
    t.string "status", default: "aberta", null: false
    t.datetime "aberta_em", null: false
    t.datetime "fechada_em"
    t.decimal "valor_total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "forma_pagamento"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aberta_em"], name: "index_comandas_on_aberta_em"
    t.index ["abertura_user_id"], name: "index_comandas_on_abertura_user_id"
    t.index ["caixa_id"], name: "index_comandas_on_caixa_id"
    t.index ["mesa_id"], name: "index_comandas_on_mesa_aberta", unique: true, where: "((status)::text = 'aberta'::text)"
    t.index ["mesa_id"], name: "index_comandas_on_mesa_id"
    t.index ["pagamento_user_id"], name: "index_comandas_on_pagamento_user_id"
    t.index ["status"], name: "index_comandas_on_status"
    t.check_constraint "valor_total >= 0::numeric", name: "comandas_total_nao_negativo"
  end

  create_table "item_comandas", force: :cascade do |t|
    t.bigint "comanda_id", null: false
    t.bigint "produto_id", null: false
    t.string "descricao", null: false
    t.decimal "quantidade", precision: 10, scale: 3, null: false
    t.decimal "valor_unitario", precision: 10, scale: 2, null: false
    t.decimal "subtotal", precision: 10, scale: 2, null: false
    t.string "observacao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comanda_id"], name: "index_item_comandas_on_comanda_id"
    t.index ["produto_id"], name: "index_item_comandas_on_produto_id"
    t.check_constraint "quantidade > 0::numeric", name: "itens_quantidade_positiva"
    t.check_constraint "subtotal >= 0::numeric", name: "itens_subtotal_nao_negativo"
    t.check_constraint "valor_unitario >= 0::numeric", name: "itens_valor_unitario_nao_negativo"
  end

  create_table "mesas", force: :cascade do |t|
    t.integer "numero", null: false
    t.string "nome"
    t.boolean "ativo", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["numero"], name: "index_mesas_on_numero", unique: true
    t.check_constraint "numero > 0", name: "mesas_numero_positivo"
  end

  create_table "movimentacao_estoques", force: :cascade do |t|
    t.bigint "produto_id", null: false
    t.bigint "user_id", null: false
    t.string "tipo", null: false
    t.decimal "quantidade", precision: 10, scale: 3, null: false
    t.string "motivo", null: false
    t.string "observacao"
    t.datetime "ocorrido_em", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ocorrido_em"], name: "index_movimentacao_estoques_on_ocorrido_em"
    t.index ["produto_id"], name: "index_movimentacao_estoques_on_produto_id"
    t.index ["tipo"], name: "index_movimentacao_estoques_on_tipo"
    t.index ["user_id"], name: "index_movimentacao_estoques_on_user_id"
    t.check_constraint "quantidade > 0::numeric", name: "movimentacoes_estoque_quantidade_positiva"
  end

  create_table "movimentacao_financeiras", force: :cascade do |t|
    t.bigint "caixa_id", null: false
    t.bigint "user_id", null: false
    t.bigint "categoria_financeira_id", null: false
    t.string "tipo", null: false
    t.string "descricao", null: false
    t.decimal "valor", precision: 10, scale: 2, null: false
    t.string "forma_pagamento", default: "nao_informada", null: false
    t.datetime "ocorrido_em", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "comanda_id"
    t.index ["caixa_id"], name: "index_movimentacao_financeiras_on_caixa_id"
    t.index ["categoria_financeira_id"], name: "index_movimentacao_financeiras_on_categoria_financeira_id"
    t.index ["comanda_id"], name: "index_movimentacao_financeiras_on_comanda_id"
    t.index ["comanda_id"], name: "index_movimentacoes_on_comanda_unica", unique: true
    t.index ["forma_pagamento"], name: "index_movimentacao_financeiras_on_forma_pagamento"
    t.index ["ocorrido_em"], name: "index_movimentacao_financeiras_on_ocorrido_em"
    t.index ["tipo"], name: "index_movimentacao_financeiras_on_tipo"
    t.index ["user_id"], name: "index_movimentacao_financeiras_on_user_id"
    t.check_constraint "valor > 0::numeric", name: "movimentacoes_valor_positivo"
  end

  create_table "produtos", force: :cascade do |t|
    t.string "nome", null: false
    t.bigint "categoria_produto_id", null: false
    t.decimal "quantidade_atual", precision: 10, scale: 3, default: "0.0", null: false
    t.string "unidade", null: false
    t.decimal "estoque_minimo", precision: 10, scale: 3, default: "0.0", null: false
    t.boolean "ativo", default: true, null: false
    t.decimal "preco_custo", precision: 10, scale: 2
    t.decimal "preco_venda", precision: 10, scale: 2
    t.boolean "disponivel_venda", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ativo", "disponivel_venda"], name: "index_produtos_on_ativo_and_disponivel_venda"
    t.index ["categoria_produto_id"], name: "index_produtos_on_categoria_produto_id"
    t.check_constraint "estoque_minimo >= 0::numeric", name: "produtos_minimo_nao_negativo"
    t.check_constraint "preco_custo IS NULL OR preco_custo >= 0::numeric", name: "produtos_custo_nao_negativo"
    t.check_constraint "preco_venda IS NULL OR preco_venda >= 0::numeric", name: "produtos_venda_nao_negativo"
    t.check_constraint "quantidade_atual >= 0::numeric", name: "produtos_saldo_nao_negativo"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "caixas", "users"
  add_foreign_key "caixas", "users", column: "fechamento_user_id"
  add_foreign_key "comandas", "caixas"
  add_foreign_key "comandas", "mesas"
  add_foreign_key "comandas", "users", column: "abertura_user_id"
  add_foreign_key "comandas", "users", column: "pagamento_user_id"
  add_foreign_key "item_comandas", "comandas"
  add_foreign_key "item_comandas", "produtos"
  add_foreign_key "movimentacao_estoques", "produtos"
  add_foreign_key "movimentacao_estoques", "users"
  add_foreign_key "movimentacao_financeiras", "caixas"
  add_foreign_key "movimentacao_financeiras", "categoria_financeiras"
  add_foreign_key "movimentacao_financeiras", "comandas"
  add_foreign_key "movimentacao_financeiras", "users"
  add_foreign_key "produtos", "categoria_produtos"
end
