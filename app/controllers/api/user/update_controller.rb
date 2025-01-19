module Api
  module User
    class UpdateController < Api::Controller
      def phase_invoke
        begin
          @current_user.assign_attributes(params_user_update)
          if @current_user.invalid?
            render json: @current_user.errors, status: :bad_request
            return
          end

          if @current_user.save
            render json: @current_user.res({ root: true }, @current_user)
          else
            render json: @current_user.errors, status: :unprocessable_entity
          end
        rescue ActiveRecord::StaleObjectError
          render json: { error: "他のユーザーによって更新されています。最新のデータを取得してください" }, status: :conflict
        end
      end

      private

      def params_user_update
        params.require(:user).permit(:email, :bio, :image, :lock_version)
      end
    end
  end
end
