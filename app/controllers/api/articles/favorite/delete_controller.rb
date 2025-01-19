module Api
  module Articles
    module Favorite
      class DeleteController < Api::Controller
        def phase_invoke
          article = Article.find_by(slug: params[:slug])
          if article.nil?
            return [ { errors: "失敗" }, :not_found ]
          end

          favorite = article.favorites.find_by(user_id: @current_user.id, article_id: article.id)

          if favorite.nil?
            # 何もせずに正常終了
            return [ res_article(article), :ok ]
          end

          if favorite.destroy
            [ res_article(article), :ok ]
          else
            [ { errors: "失敗" }, :unprocessable_entity ]
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
