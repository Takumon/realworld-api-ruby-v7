module Api
  module Users
    class LoginController < Api::Controller
      set :is_required_auth, false

      def phase_invoke
        req = LoginRequest.new(params_login)

        if req.invalid?
          raise ValidationError.new(req.errors, :bad_request)
        end

        user = ::User.authenticate_by(email: req.email, password: req.password)
        if user.nil?
          raise ValidationError.new("メールアドレスとパスワードに組み合わせが間違っています", :unauthorized)
        end

        [ res_user_with_token(user), :ok ]
      end

      private
      def params_login
        params.require(:user).permit(:email, :password)
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
