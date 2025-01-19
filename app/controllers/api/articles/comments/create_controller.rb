module Api
  module Articles
    module Comments
      class CreateController < Api::Controller
        def phase_invoke
          article = Article.find_by(slug: params[:slug])
          if article.nil?
            return [ { errors: "失敗" }, :not_found ]
          end

          comment = Comment.new(**params_comment_create, article:, user: @current_user)
          if comment.invalid?
            return [ { errors: comment.errors }, :bad_request ]
          end

          if comment.save
            [ res_comment(comment), :ok ]
          else
            [ { errors: "失敗" }, :unprocessable_entity ]
          end
        end

        private

        def params_comment_create
          params.require(:comment).permit(
            :body
          )
        end

        def res_comment(comment)
          comment.res({ root: true }, @current_user)
        end
      end
    end
  end
end
