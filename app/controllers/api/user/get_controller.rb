module Api
  module User
    class GetController < Api::Controller
      def phase_invoke
        [ @current_user.res({ root: true }, @current_user), :ok ]
      end

      private
      # nothing
    end
  end
end
