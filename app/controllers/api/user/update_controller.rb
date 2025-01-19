module Api
  module User
    class UpdateController < Api::Controller
      def phase_invoke
        begin
          @current_user.assign_attributes(params_user_update)
          if @current_user.invalid?
            return [ @current_user.errors, :bad_request ]
          end

          if @current_user.save
            [ @current_user.res({ root: true }, @current_user) ]
          else
            [ @current_user.errors, :unprocessable_entity ]
          end
        rescue ActiveRecord::StaleObjectError
          [ { error: "他のユーザーによって更新されています。最新のデータを取得してください" }, :conflict ]
        end
      end

      private

      def params_user_update
        params.require(:user).permit(:email, :bio, :image, :lock_version)
      end
    end
  end
end
