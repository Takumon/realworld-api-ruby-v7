module Api
  module Profiles
    class UnfollowController < Api::Controller
      def phase_invoke
        user = ::User.find_by(username: params[:username])
        if user.nil?
          return [ { errors: [ { 'username': "存在しないユーザー名です" } ] },  :not_found ]
        end

        relationship = Relationship.find_by(follower: @current_user, followed: user)
        if relationship.nil?
          # フォローしていないなので何もしない
          return [ user.res({ root: true }, @current_user) ]
        end

        if relationship.destroy
          user.reload # フォロー状態を取得
          [ user.res({ root: true }, @current_user), :ok ]
        else
          [ "失敗",   :unprocessable_entity ]
        end
      end

      private
      # nothing
    end
  end
end
