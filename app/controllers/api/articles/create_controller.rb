module Api
  module Articles
    class CreateController < Api::Controller
      def phase_invoke
        article = Article.new(params_article_create)
        article.user = @current_user # 投稿者は自分とする

        if article.invalid?
          render json: { errors: article.errors }, status: :bad_request
          return
        end

        if article.save_with_relations
          render json: res_article(article), status: :created
        else
          render json: "失敗", status: :unprocessable_entity
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
