module Api
  module Articles
    module Favorite
      class DeleteController < Api::Controller
        def phase_invoke
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

        private
        def res_article(article)
          article.res({ root: true }, @current_user)
        end
      end
    end
  end
end
