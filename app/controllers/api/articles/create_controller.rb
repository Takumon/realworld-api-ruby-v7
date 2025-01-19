module Api
  module Articles
    class CreateController < Api::Controller
      def phase_invoke
        article = Article.new(params_article_create)
        article.user = @current_user # 投稿者は自分とする

        if article.invalid?
          return [ { errors: article.errors }, :bad_request ]
        end

        if article.save_with_relations
          [ res_article(article), :created ]
        else
          [ { errors: "失敗" }, :unprocessable_entity ]
        end
      end

      private
        def params_article_create
          params.require(:article).permit(
            :slug,
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
