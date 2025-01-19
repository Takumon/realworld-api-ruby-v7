class Api::Controller < ApplicationController
  def phase_response(data)
    render json: generate_response_json(data, errors),
          status: self.status,
          content_type: "application/json",
          charset: "utf-8"
  end

  def generate_response_json(data, errors)
    { data:, errors: }
  end
end
