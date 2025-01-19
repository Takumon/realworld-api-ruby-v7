module Api
  module Articles
    class UpdateController < Api::Controller
      def phase_invoke
        article = Article.find_by(slug: params[:slug], user_id: @current_user.id)  # 自分の記事のみ検索

        if article.nil?
          return [ { errors: "失敗" },  :not_found ]
        end

        req = ArticleUpdateRequest.new(params_article_update)
        if req.invalid?
          return [ article.errors,  :bad_request ]
        end

        req.bind_to(article)
        if article.save_with_relations
          [ res_article(article),  :ok ]
        else
          [ { errors: "失敗" },  :unprocessable ]
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
