Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    post "users/login", to: "users#login"
    post "users", to: "users#create"

    get "user", to: "users#show"
    put "user", to: "users#update"

    get "profiles/:username", to: "profiles#show"
    post "profiles/:username/follow", to: "profiles#follow"
    delete "profiles/:username/follow", to: "profiles#unfollow"

    get "articles", to: "articles#index"
    post "articles", to: "articles#create"
    get "articles/feed", to: "articles#feed"
    get "articles/:slug", to: "articles#show"
    put "articles/:slug", to: "articles#update"
    delete "articles/:slug", to: "articles#destroy"
    post "articles/:slug/favorite", to: "articles#favorite"
    delete "articles/:slug/favorite", to: "articles#unfavorite"
  end
end
