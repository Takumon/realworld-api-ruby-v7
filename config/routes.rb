Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    post "users/login", to: "users#login"
    post "users", to: "users#create"

    get "user", to: "users#show"
    put "user", to: "users#update"

    post "articles", to: "articles#create"
  end
end
