class Api::ArticlesController < ApplicationController
  before_action :authenticate_request, only: [ :show, :create, :update, :destroy, :index ]

  def index
    query = ArticlesQuery.new(params_articles_query)
    if query.invalid?
      render json: query.errors, status: :bad_request
      return
    end

    list = Article.sorted_by_updated_at_desc
    if query.author.present?
      list = list.joins(:user).where(user: { username: query.author })
    end
    list = list.offset(query.offset).limit(query.limit)
    render json: res_articles(list)
  end

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

    if article.save_with_relations
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

    req = ArticleUpdateRequest.new(params_article_update)
    if req.invalid?
      render json: article.errors, status: :bad_request
      return
    end

    req.bind_to(article)
    if article.save_with_relations
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
    def params_articles_query
      params.permit(:offset, :limit, :author)
    end

    def params_article_create
      params.require(:article).permit(
        :slug,
        :title,
        :description,
        :body,
        tagList: []
      )
    end

    def params_article_update
      params.require(:article).permit(
        :title,
        :description,
        :body,
        tagList: []
      )
    end

    def res_article(article)
      {
        article: article_to_json(article)
      }
    end

    def res_articles(articles)
      {
        articles: articles.map { |article| article_to_json(article) },
        articlesCount: articles.count
      }
    end

    def article_to_json(article)
      article.as_json(only: [
          :id,
          :slug,
          :title,
          :description,
          :body
        ]).merge({
          tagList: article.tags.map(&:name),
          author: article.user.as_json(only: [
            :username,
            :bio,
            :image
            # TODO :following を追加
          ])
        })
    end
end
