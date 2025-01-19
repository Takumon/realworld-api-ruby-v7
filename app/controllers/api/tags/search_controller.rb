module Api
  module Tags
    class SearchController < Api::Controller
      skip_before_action :authenticate_request

      def phase_invoke
        [ { tags: Tag.pluck(:name) }, :ok ]
      end
    end
  end
end
