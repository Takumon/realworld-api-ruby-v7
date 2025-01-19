module Api
  module Articles
    module Comments
      class CreateController < Api::Controller
        def phase_invoke
          article = Article.find_by(slug: params[:slug])
          if article.nil?
            render json: "失敗", status: :not_found
            return
          end

          comment = Comment.new(**params_comment_create, article:, user: @current_user)
          if comment.invalid?
            render json: { errors: comment.errors }, status: :bad_request
            return
          end

          if comment.save
            render json: res_comment(comment), status: :ok
          else
            render json: "失敗", status: :unprocessable_entity
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
