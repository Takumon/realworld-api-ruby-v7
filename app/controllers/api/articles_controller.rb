class Api::ArticlesController < ApplicationController
  before_action :authenticate_request, only: [ :create ]

  def create
    article = Article.new(params_article_create)
    article.user = @current_user

    if article.invalid?
      render json: { errors: article.errors }, status: :bad_request
      return
    end

    if article.save
      render json: res_article(article), status: :created
    else
      render json: "失敗", status: :unprocessable_entity
    end
  end

  private
    def params_article_create
      params.require(:article).permit(
        :slug,
        :title,
        :description,
        :body
      )
    end

    def res_article(article)
      {
        article: article.as_json(only: [
          :id,
          :slug,
          :title,
          :description,
          :body
        ]).merge({
          author: article.user.as_json(only: [
            :username,
            :bio,
            :image
            # TODO :following を追加
          ])
        })
      }
    end
end
