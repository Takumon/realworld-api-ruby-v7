module Api
  module Users
    class CreateController < Api::Controller
      skip_before_action :authenticate_request

      def phase_invoke
        user = ::User.new(params_user_create)

        if user.invalid?
          return [ user.errors, :bad_request ]
        end

        if user.save
          [ res_user_with_token(user), :created ]
        else
          [ { errors: "失敗" }, :unprocessable_entity ]
        end
      end

      private

      def params_user_create
        params.require(:user).permit(:username, :email, :password)
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
