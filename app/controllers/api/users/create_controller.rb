module Api
  module Users
    class CreateController < Api::Controller
      skip_before_action :authenticate_request

      def phase_invoke
        user = ::User.new(params_user_create)

        if user.invalid?
          render json: user.errors, status: :bad_request
          return
        end

        if user.save
          render json: res_user_with_token(user), status: :created
        else
          render json: "失敗", status: :unprocessable_entity
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
