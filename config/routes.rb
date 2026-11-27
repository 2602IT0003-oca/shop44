Rails.application.routes.draw do
  # ユーザ認証
  devise_for :users

  # マイページ
  resources :mypage, only: [:show]

  # カート関連
  resources :carts, only: [:show, :index] do
    collection do
      post :add_product # カートに商品を追加（add_product_carts_path）
    end
    member do
      delete :remove_item # カートから商品を削除（remove_item_cart_path）
      patch :update_quantity # カート内の商品数を変更（update_quantity_cart_path）
    end
  end

  # 商品登録
  get 'products/new', to: 'products#new', as: 'new_product'
  post 'products', to: 'products#create'

  # 商品一覧
  get 'products', to: 'products#index'

  # 商品詳細
  get 'products/:id', to: 'products#show', as: 'product'

  # 商品編集
  get 'products/:id/edit', to: 'products#edit', as: 'edit_product'
  patch 'products/:id', to: 'products#update'

  # 商品削除
  delete 'products/:id', to: 'products#destroy', as: 'destroy_product'

  # トップページ
  root to: "homes#top"

  # 注文関連
  resources :orders, only: [:index, :new, :create] do
    collection do
      post :confirm
    end

    member do
      get :complete
    end
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # ユーザーのカート内の商品操作
  resources :cart_items, only: [:create, :update, :destroy]
end