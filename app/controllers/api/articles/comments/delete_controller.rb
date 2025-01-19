module Api
  module Articles
    module Comments
      class DeleteController < Api::Controller
        def phase_invoke
          comment = Comment.find_by(id: params[:id])
          if comment.nil?
            # 存在しないので何もせずに正常終了
            render json: {}, status: :ok
            return
          end

          if comment.user_id != @current_user.id
            render json: "失敗", status: :forbidden
            return
          end

          if comment.destroy
            render json: {}, status: :ok
          else
            render json: "失敗", status: :unprocessable_entity
          end
        end

        private
        # nothing
      end
    end
  end
end
