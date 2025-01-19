module Api
  module Articles
    class UpdateController < Api::Controller
      def phase_invoke
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

      private
        def params_article_update
          params.require(:article).permit(
            :title,
            :description,
            :body,
            tagList: []
          )
        end

        def res_article(article)
          article.res({ root: true }, @current_user)
        end
    end
  end
end
