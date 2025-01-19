module Api
  module User
    class UpdateController < Api::Controller
      def phase_invoke
        begin
          @current_user.assign_attributes(params_user_update)
          if @current_user.invalid?
            raise ValidationError.new(@current_user.errors, :bad_request)
          end

          unless @current_user.save
            raise ValidationError.new(@current_user.errors, :unprocessable_entity)
          end

          [ @current_user.res({ root: true }, @current_user) ]
        rescue ActiveRecord::StaleObjectError
          raise ValidationError.new("他のユーザーによって更新されています。最新のデータを取得してください", :conflict)
        end
      end

      private

      def params_user_update
        params.require(:user).permit(:email, :bio, :image, :lock_version)
      rescue ActionController::ParameterMissing => e
        raise ValidationError.new("リクエストが不正です", :bad_request)
      end
    end
  end
end
