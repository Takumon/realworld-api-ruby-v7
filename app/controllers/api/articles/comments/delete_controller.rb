module Api
  module Articles
    module Comments
      class DeleteController < Api::Controller
        def phase_invoke
          comment = Comment.find_by(id: params[:id])
          if comment.nil?
            # 存在しないので何もせずに正常終了
            return [ {},  :ok ]
          end

          if comment.user_id != @current_user.id
            raise ValidationError.new("失敗", :forbidden)
          end

          unless comment.destroy
            raise ValidationError.new("失敗", :unprocessable_entity)
          end

          [ {},  :ok ]
        end

        private
        # nothing
      end
    end
  end
end
