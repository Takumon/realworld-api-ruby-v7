module Api
  class HealthController < Api::Controller
    set :is_required_auth, false

    def phase_invoke
      [ health_data, :ok ]
    end
  end
end
