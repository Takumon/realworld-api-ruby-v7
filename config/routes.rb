Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    post "users/login", to: "users#login"
    post "users", to: "users#create"

    get "user", to: "users#show"
    put "user", to: "users#update"

    get "articles", to: "articles#index"
    get "articles/feed", to: "articles#feed"
    get "articles/:slug", to: "articles#show"
    post "articles", to: "articles#create"
    put "articles/:slug", to: "articles#update"
    delete "articles/:slug", to: "articles#destroy"

    get "profiles/:username", to: "profiles#show"
    post "profiles/:username/follow", to: "profiles#follow"
    delete "profiles/:username/follow", to: "profiles#unfollow"
  end
end
