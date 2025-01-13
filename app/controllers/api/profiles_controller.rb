class Api::ProfilesController < ApplicationController
  before_action :authenticate_request

  def show
    user = User.find_by(username: params[:username])
    if user.nil?
      render json: { errors: [ { 'username': "存在しないユーザー名です" } ] }, status: :not_found
      return
    end

    render json: res_profile(user)
  end

  def follow
    user = User.find_by(username: params[:username])
    if user.nil?
      render json: { errors: [ { 'username': "存在しないユーザー名です" } ] }, status: :not_found
      return
    end

    relationship = Relationship.find_by(follower: @current_user, followed: user)
    if relationship.present?
      # フォロー済なので何もしない
      render json: res_profile(user)
      return
    end

    relationship = Relationship.new(follower: @current_user, followed: user)
    if relationship.invalid?
      render json: { errors: relationship.errors }, status: :bad_request
      return
    end

    if relationship.save
      user.reload # フォロー状態を取得
      render json: res_profile(user)
    else
      render json: "失敗",  status: :unprocessable_entity
    end
  end

  def unfollow
    user = User.find_by(username: params[:username])
    if user.nil?
      render json: { errors: [ { 'username': "存在しないユーザー名です" } ] }, status: :not_found
      return
    end

    relationship = Relationship.find_by(follower: @current_user, followed: user)
    if relationship.nil?
      # フォローしていないなので何もしない
      render json: res_profile(user)
      return
    end

    if relationship.destroy
      user.reload # フォロー状態を取得
      render json: res_profile(user)
    else
      render json: "失敗",  status: :unprocessable_entity
    end
  end

  private
    def res_profile(user)
      {
        'user': {
          'username': user.username,
          'bio': user.bio,
          'image': user.image,
          'following': @current_user.following.exists?(user.id)
        }
      }
    end
end
