class Api::UsersController < ApplicationController
  before_action :authenticate_request, only: [ :show ]
  def show
    user = User.find(@current_user.id)
    render json: { user: user.as_json(only: [ :username, :email, :bio, :image ]) }
  end

  def login
    req = LoginRequest.new(login_params)

    if req.invalid?
      render json: req.errors, status: :bad_request
      return
    end

    user = User.authenticate_by(email: req.email, password: req.password)
    if user.nil?
      render json: { error: "メールアドレスとパスワードに組み合わせが間違っています" }, status: :unauthorized
      return
    end

    render json: res_with_token(user)
  end

  def create
    user = User.new(user_create_params)

    if user.invalid?
      render json: user.errors, status: :bad_request
      return
    end

    if user.save
      render json: res_with_token(user), status: :created
    else
      render json: "失敗", status: :unprocessable
    end
  end

  private
    def login_params
      params.require(:user).permit(:email, :password)
    end

    def user_create_params
      params.require(:user).permit(:username, :email, :password)
    end

    def res_with_token(user)
      {
        user: {
          **user.as_json(only: [ :username, :email, :bio, :image ]),
          token: generate_token(user)
        }
      }
    end
end
