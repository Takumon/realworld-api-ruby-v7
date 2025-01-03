class UsersController < ApplicationController
  wrap_parameters :user, include: [ :username, :email, :password ]

  def login
    render json: "OK"
  end

  def create
    user = User.new(user_params_create)

    if user.invalid?
      render json: user.errors, status: :bad_request
      return
    end

    if user.save
      render json: user
    else
      render json: "失敗"
    end
  end

  private
    def user_params_create
      params.require(:user).permit(:username, :email, :password)
    end
end
