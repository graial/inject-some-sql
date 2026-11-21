Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "store" => "store#index", as: :store_index
  resources :products, only: [ :show ]

  post "query/:action", controller: :query
  get "examples", to: "query#examples"

  root "query#index"
end
