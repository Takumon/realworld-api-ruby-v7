module Api
  module Articles
    class CreateController < Api::Controller
      def phase_invoke
        article = Article.new(params_article_create)
        article.user = @current_user # 投稿者は自分とする

        if article.invalid?
          raise ValidationError.new(article.errors, :bad_request)
        end

        unless article.save_with_relations
          raise ValidationError.new("失敗", :unprocessable_entity)
        end

        [ res_article(article), :created ]
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
        rescue ActionController::ParameterMissing => e
          raise ValidationError.new("リクエストが不正です", :bad_request)
        end

        def res_article(article)
          article.res({ root: true }, @current_user)
        end
    end
  end
end
