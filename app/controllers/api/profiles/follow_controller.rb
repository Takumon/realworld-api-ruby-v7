module Api
  module Profiles
    class FollowController < Api::Controller
      def phase_invoke
        user = ::User.find_by(username: params[:username])
        if user.nil?
          raise ValidationError.new({ 'username': "存在しないユーザー名です" }, :not_found)
        end

        relationship = Relationship.find_by(follower: @current_user, followed: user)
        if relationship.present?
          # フォロー済なので何もしない
          return [ user.res({ root: true }, @current_user) ]
        end

        relationship = Relationship.new(follower: @current_user, followed: user)
        if relationship.invalid?
          raise ValidationError.new(relationship.errors, :bad_request)
        end

        unless relationship.save
          raise ValidationError.new("失敗", :unprocessable_entity)
        end

        user.reload # フォロー状態を取得
        [ user.res({ root: true }, @current_user), :ok ]
      end

      private
      # nothing
    end
  end
end
