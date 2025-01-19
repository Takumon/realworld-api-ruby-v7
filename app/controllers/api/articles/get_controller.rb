module Api
  module Articles
    class GetController < Api::Controller
      def phase_invoke
        article = Article.find_by(slug: params[:slug], user_id: @current_user.id) # 自分の記事のみ検索

        if article.nil?
          render json: "失敗", status: :not_found
          return
        end

        render json: res_article(article), status: :ok
      end

      private

        def res_article(article)
          article.res({ root: true }, @current_user)
        end
    end
  end
end
