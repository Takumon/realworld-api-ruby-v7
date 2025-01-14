class Api::UsersController < ApplicationController
  before_action :authenticate_request, except: [ :login, :create ]
  def show
    render json: res_user(@current_user)
  end

  def update
    begin
      @current_user.assign_attributes(params_user_update)
      if @current_user.invalid?
        render json: @current_user.errors, status: :bad_request
        return
      end

      if @current_user.save
        render json: res_user(@current_user)
      else
        debugger
        render json: @current_user.errors, status: :unprocessable_entity
      end
    rescue ActiveRecord::StaleObjectError
      render json: { error: "他のユーザーによって更新されています。最新のデータを取得してください" }, status: :conflict
    end
  end

  def login
    req = LoginRequest.new(params_login)

    if req.invalid?
      render json: req.errors, status: :bad_request
      return
    end

    user = User.authenticate_by(email: req.email, password: req.password)
    if user.nil?
      render json: { error: "メールアドレスとパスワードに組み合わせが間違っています" }, status: :unauthorized
      return
    end

    render json: res_user_with_token(user)
  end

  def create
    user = User.new(params_user_create)

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
    def params_login
      params.require(:user).permit(:email, :password)
    end

    def params_user_update
      params.require(:user).permit(:email, :bio, :image, :lock_version)
    end

    def params_user_create
      params.require(:user).permit(:username, :email, :password)
    end

    def res_user(user)
      {
        user: {
          **user.as_json(only: [ :username, :email, :bio, :image, :lock_version ])
        }
      }
    end


    def res_user_with_token(user)
      {
        user: {
          **res_user(user)[:user],
          token: generate_token(user)
        }
      }
    end
end
