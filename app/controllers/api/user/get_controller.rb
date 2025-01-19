module Api
  module User
    class GetController < Api::Controller
      def phase_invoke
        render json: @current_user.res({ root: true }, @current_user)
      end

      private
      # nothing
    end
  end
end
