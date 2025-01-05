class Api::ArticlesController < ApplicationController
  before_action :authenticate_request, only: [ :show, :create, :update, :destroy ]

  def show
    article = Article.find_by(slug: params[:slug], user_id: @current_user.id) # 自分の記事のみ検索

    if article.nil?
      render json: "失敗", status: :not_found
      return
    end

    render json: res_article(article), status: :ok
  end

  def create
    article = Article.new(params_article_create)
    article.user = @current_user # 投稿者は自分とする

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

  def update
    article = Article.find_by(slug: params[:slug], user_id: @current_user.id)  # 自分の記事のみ検索

    if article.nil?
      render json: "失敗", status: :not_found
      return
    end

    article.assign_attributes(params_article_update)
    if article.invalid?
      render json: article.errors, status: :bad_request
      return
    end

    if article.save
      render json: res_article(article), status: :ok
    else
      render json: "失敗", status: :unprocessable
    end
  end

  def destroy
    article = Article.find_by(slug: params[:slug], user_id: @current_user.id)  # 自分の記事のみ検索

    if article.nil?
      render json: "失敗", status: :not_found
      return
    end

    if article.destroy
      render json: "ok", status: :ok
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

    def params_article_update
      params.require(:article).permit(
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
