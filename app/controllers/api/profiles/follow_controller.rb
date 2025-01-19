module Api
  module Profiles
    class FollowController < Api::Controller
      def phase_invoke
        user = ::User.find_by(username: params[:username])
        if user.nil?
          render json: { errors: [ { 'username': "存在しないユーザー名です" } ] }, status: :not_found
          return
        end

        relationship = Relationship.find_by(follower: @current_user, followed: user)
        if relationship.present?
          # フォロー済なので何もしない
          render json: user.res({ root: true }, @current_user)
          return
        end

        relationship = Relationship.new(follower: @current_user, followed: user)
        if relationship.invalid?
          render json: { errors: relationship.errors }, status: :bad_request
          return
        end

        if relationship.save
          user.reload # フォロー状態を取得
          render json: user.res({ root: true }, @current_user)
        else
          render json: "失敗",  status: :unprocessable_entity
        end
      end

      private
      # nothing
    end
  end
end
