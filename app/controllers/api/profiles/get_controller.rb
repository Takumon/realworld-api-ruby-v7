module Api
  module Profiles
    class GetController < Api::Controller
      def phase_invoke
        user = ::User.find_by(username: params[:username])
        if user.nil?
          render json: { errors: [ { 'username': "存在しないユーザー名です" } ] }, status: :not_found
          return
        end

        render json: user.res({ root: true }, @current_user)
      end

      private
      # nothing
    end
  end
end
