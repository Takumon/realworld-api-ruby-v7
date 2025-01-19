module Api
  module Tags
    class SearchController < Api::Controller
      set :is_required_auth, false

      def phase_invoke
        [ { tags: Tag.pluck(:name) }, :ok ]
      end
    end
  end
end
