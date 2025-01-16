class Api::ArticlesController < ApplicationController
  before_action :authenticate_request

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

    if query.tag.present?
      list = list.joins(:tags).where(tags: { name: query.tag })
    end

    if query.favorited.present?
      list = list.joins(favorites: :user).where(users: { username: query.favorited })
    end

    list = list.offset(query.offset).limit(query.limit)
    render json: res_articles(list)
  end

  def feed
    query = ArticlesQuery.new(params_articles_feed_query)
    if query.invalid?
      render json: query.errors, status: :bad_request
      return
    end

    list = Article.sorted_by_updated_at_desc
                  .joins(:user).where(users: { id: @current_user.following_ids || [] })
                  .offset(query.offset)
                  .limit(query.limit)

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


  def favorite
    article = Article.find_by(slug: params[:slug])
    if article.nil?
      render json: "失敗", status: :not_found
      return
    end

    if article.favorited_users.exists?(@current_user.id)
      # 何もせずに正常終了
      render json: res_article(article), status: :ok
      return
    end

    favorite = Favorite.new(user: @current_user, article: article)
    if favorite.invalid?
      render json: { errors: favorite.errors }, status: :bad_request
      return
    end

    if favorite.save
      render json: res_article(article), status: :ok
    else
      render json: "失敗", status: :unprocessable_entity
    end
  end


  def unfavorite
    article = Article.find_by(slug: params[:slug])
    if article.nil?
      render json: "失敗", status: :not_found
      return
    end

    favorite = article.favorites.find_by(user_id: @current_user.id, article_id: article.id)

    if favorite.nil?
      # 何もせずに正常終了
      render json: res_article(article), status: :ok
      return
    end

    if favorite.destroy
      render json: res_article(article), status: :ok
    else
      render json: "失敗", status: :unprocessable_entity
    end
  end


  def comments
    article = Article.find_by(slug: params[:slug])
    if article.nil?
      render json: "失敗", status: :not_found
      return
    end

    render json: res_comments(article.comments), status: :ok
  end

  def create_comment
    article = Article.find_by(slug: params[:slug])
    if article.nil?
      render json: "失敗", status: :not_found
      return
    end

    comment = Comment.new(**params_comment_create, article:, user: @current_user)
    if comment.invalid?
      render json: { errors: comment.errors }, status: :bad_request
      return
    end

    if comment.save
      render json: res_comment(comment), status: :ok
    else
      render json: "失敗", status: :unprocessable_entity
    end
  end

  def delete_comment
    comment = Comment.find_by(id: params[:id])
    if comment.nil?
      # 存在しないので何もせずに正常終了
      render json: {}, status: :ok
      return
    end

    if comment.user_id != @current_user.id
      render json: "失敗", status: :forbidden
      return
    end

    if comment.destroy
      render json: {}, status: :ok
    else
      render json: "失敗", status: :unprocessable_entity
    end
  end


  private
    def params_articles_query
      params.permit(:offset, :limit, :author, :tag, :favorited)
    end
    def params_articles_feed_query
      params.permit(:offset, :limit)
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

    def params_comment_create
      params.require(:comment).permit(
        :body
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
          favorited: @current_user.favorites.map(&:article_id).include?(article.id),
          favoritesCount: article.favorites.count,
          author: article.user.as_json(only: [
            :username,
            :bio,
            :image
          ]).merge({
            following: @current_user.following.exists?(article.user.id)
          })
        })
    end

    def res_comments(comments)
      {
        comments: comments.map { |comment| comment_to_json(comment) }
      }
    end

    def res_comment(comment)
      {
        comment: comment_to_json(comment)
      }
    end

    def comment_to_json(comment)
      comment.as_json(only: [
          :id,
          :body,
          :created_at,
          :updated_at
          ]).merge({
            author: comment.user.as_json(only: [
              :username,
              :bio,
              :image
            ])
          })
    end
end
