Rails.application.routes.draw do
  devise_for :users, only: :sessions, path: "", path_names: { sign_in: "entrar", sign_out: "sair" }

  root "dashboard#index"
  get "dashboard", to: "dashboard#index"

  resources :caixas, path: "caixa", only: [ :index, :new, :create, :show ] do
    member do
      get :fechar
      patch :confirmar_fechamento
    end
  end

  resources :movimentacao_financeiras, path: "movimentacoes", controller: "movimentacoes", only: [ :index, :new, :create, :show ]
  resources :movimentacao_estoques, path: "estoque", controller: "movimentacao_estoques", only: [ :index, :new, :create, :show ]

  resources :produtos, except: [ :destroy ]
  resources :mesas, except: [ :destroy ]
  resources :comandas, only: [ :index, :show, :create ] do
    member do
      get :pagar
      patch :confirmar_pagamento
    end
  end
  post "comandas/:comanda_id/itens", to: "itens#create", as: :comanda_itens
  patch "comandas/:comanda_id/itens/:id", to: "itens#update", as: :comanda_item
  delete "comandas/:comanda_id/itens/:id", to: "itens#destroy"

  resources :relatorios, only: [ :index ] do
    collection do
      get :movimentacoes
      get :caixas
      get :produtos
      get :comandas
    end
  end

  get "up", to: "rails/health#show", as: :rails_health_check
end
