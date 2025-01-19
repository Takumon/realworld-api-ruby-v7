module Api
  module Users
    class LoginController < Api::Controller
      skip_before_action :authenticate_request

      def phase_invoke
        req = LoginRequest.new(params_login)

        if req.invalid?
          render json: req.errors, status: :bad_request
          return
        end

        user = ::User.authenticate_by(email: req.email, password: req.password)
        if user.nil?
          render json: { error: "メールアドレスとパスワードに組み合わせが間違っています" }, status: :unauthorized
          return
        end

        render json: res_user_with_token(user)
      end

      private
      def params_login
        params.require(:user).permit(:email, :password)
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
