module Api
  module Articles
    module Favorite
      class CreateController < Api::Controller
        def phase_invoke
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

          favorite = ::Favorite.new(user: @current_user, article: article)
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

        private
        def res_article(article)
          article.res({ root: true }, @current_user)
        end
      end
    end
  end
end
