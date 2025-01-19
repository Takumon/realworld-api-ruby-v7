module Api
  module Articles
    class DeleteController < Api::Controller
      def phase_invoke
        article = Article.find_by(slug: params[:slug], user_id: @current_user.id)  # 自分の記事のみ検索

        if article.nil?
          return [ { errors: "失敗" },  :not_found ]
        end

        if article.destroy
          [ {},  :ok ]
        else
          [ { errors: "失敗" },  :unprocessable_entity ]
        end
      end

      private
      # nothing
    end
  end
end
