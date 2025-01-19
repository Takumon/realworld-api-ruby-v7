module Api
  module Articles
    class UpdateController < Api::Controller
      def phase_invoke
        article = Article.find_by(slug: params[:slug], user_id: @current_user.id)  # 自分の記事のみ検索

        if article.nil?
          raise ValidationError.new("失敗", :not_found)
        end

        req = ArticleUpdateRequest.new(params_article_update)
        if req.invalid?
          raise ValidationError.new(article.errors,  :bad_request)
        end

        req.bind_to(article)
        unless article.save_with_relations
          raise ValidationError.new("失敗",  :unprocessable)
        end

        [ res_article(article),  :ok ]
      end

      private
        def params_article_update
          params.require(:article).permit(
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
