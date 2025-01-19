module Api
  module Articles
    module Favorite
      class CreateController < Api::Controller
        def phase_invoke
          article = Article.find_by(slug: params[:slug])
          if article.nil?
            return [ { errors: "失敗" }, :not_found ]
          end

          if article.favorited_users.exists?(@current_user.id)
            # 何もせずに正常終了
            return [ res_article(article), :ok ]
          end

          favorite = ::Favorite.new(user: @current_user, article: article)
          if favorite.invalid?
            return [  { errors: favorite.errors }, :bad_request ]
          end

          if favorite.save
            [  res_article(article), :ok ]
          else
            [  "失敗", :unprocessable_entity ]
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
