module Api
  module Users
    class CreateController < Api::Controller
      set :is_required_auth, false

      def phase_invoke
        user = ::User.new(params_user_create)

        if user.invalid?
          raise ValidationError.new(user.errors, :bad_request)
        end

        unless user.save
          raise ValidationError.new("失敗", :unprocessable_entity)
        end

        [ res_user_with_token(user), :ok ]
      end

      private

      def params_user_create
        params.require(:user).permit(:username, :email, :password)
      rescue ActionController::ParameterMissing => e
        raise ValidationError.new("リクエストが不正です", :bad_request)
      end

      def res_user_with_token(user)
        {
          user: user.res({}, @current_user).merge({
            token: generate_token(user)
          })
        }
      end
    end
  end
end
