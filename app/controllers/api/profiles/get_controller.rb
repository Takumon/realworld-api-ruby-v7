module Api
  module Profiles
    class GetController < Api::Controller
      def phase_invoke
        user = ::User.find_by(username: params[:username])
        if user.nil?
          return [ { errors: [ { 'username': "存在しないユーザー名です" } ] },  :not_found ]
        end

        [ user.res({ root: true }, @current_user), :ok ]
      end

      private
      # nothing
    end
  end
end
