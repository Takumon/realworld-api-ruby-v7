class ApplicationController < ActionController::API
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
        false # トークンの有効期限切れ
      rescue JWT::DecodeError
        false # トークンが不正
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
