module Api
  module Articles
    class DeleteController < Api::Controller
      def phase_invoke
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
      # nothing
    end
  end
end
