module Api
  module Tags
    class SearchController < Api::Controller
      skip_before_action :authenticate_request

      def phase_invoke
        render json: { tags: Tag.pluck(:name) }
      end
    end
  end
end
