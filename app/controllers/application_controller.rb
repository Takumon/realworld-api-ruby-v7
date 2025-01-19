class ApplicationController < ActionController::API
  before_action :authenticate_request

  def invoke
    phase_invoke
  end

  def phase_invoke
    rails NotImplementedError, "You must implement #{self.class}##{__method__}"
  end

  private

    SECRET_KEY = Rails.application.credentials.secret_key_base
    JWT_ALGORITHM = "HS256"

    def authenticate_request
      token = _extract_token_from_header
      if token && decoded = _valid_token?(token)
        @current_user = User.find_by(id: decoded[:user_id])
      else
        render json: { error: "認証に失敗しました" }, status: :unauthorized
      end
    end

    def _extract_token_from_header
      h = request.headers["Authorization"]

      return nil unless h&.start_with?("Token ")

      h.split(" ").last
    end

    def _valid_token?(token)
      begin
        JWT.decode(token, SECRET_KEY, true, { algorithm: JWT_ALGORITHM }).first.symbolize_keys
      rescue JWT::ExpiredSignature
        nil
      rescue JWT::DecodeError
        nil
      end
    end

    def generate_token(user)
      payload = {
        user_id: user.id,
        exp: (DateTime.now + 1.days).to_i
      }

      JWT.encode(payload, SECRET_KEY, JWT_ALGORITHM)
    end
end
