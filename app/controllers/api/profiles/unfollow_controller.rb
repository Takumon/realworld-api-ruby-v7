module Api
  module Profiles
    class UnfollowController < Api::Controller
      def phase_invoke
        user = ::User.find_by(username: params[:username])
        if user.nil?
          render json: { errors: [ { 'username': "存在しないユーザー名です" } ] }, status: :not_found
          return
        end

        relationship = Relationship.find_by(follower: @current_user, followed: user)
        if relationship.nil?
          # フォローしていないなので何もしない
          render json: user.res({ root: true }, @current_user)
          return
        end

        if relationship.destroy
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
