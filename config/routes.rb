Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    namespace :users do
      post "/login", to: "login#invoke"
      post "", to: "create#invoke"
    end

    namespace :user do
      get "", to: "get#invoke"
      put "", to: "update#invoke"
    end

    namespace :profiles do
      get ":username", to: "get#invoke"
      post ":username/follow", to: "follow#invoke"
      delete ":username/follow", to: "unfollow#invoke"
    end

    namespace :articles do
      get "", to: "search#invoke"
      post "", to: "create#invoke"
      get "/feed", to: "feed#invoke"
      get "/:slug", to: "get#invoke"
      put "/:slug", to: "update#invoke"
      delete "/:slug", to: "delete#invoke"

      namespace :favorite, path: "/:slug/favorite" do
        post "", to: "create#invoke"
        delete "", to: "delete#invoke"
      end

      namespace :comments, path: "/:slug/comments" do
        get "", to: "search#invoke"
        post "", to: "create#invoke"
        delete "/:id", to: "delete#invoke"
      end
    end

    namespace :tags do
      get "", to: "search#invoke"
    end
  end
end
