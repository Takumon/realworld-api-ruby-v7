module Api
  class HealthController < Api::Controller
    skip_before_action :authenticate_request

    def phase_invoke
      [ health_data, :ok ]
    end
  end
end
