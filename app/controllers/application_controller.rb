class ApplicationController < ActionController::API
  include Support::Settable

  attr_accessor :request_params,
                :json_body,
                :errors

  # コントローラー処理の入口
  def invoke
    @request_params = params

    data = invoke_transaction
    phase_response(data)
  end

  def invoke_transaction
    data = nil

    invoke_block do
      phase_required_params
      phase_required_json_body

      phase_required_auth

      phase_validate
      data, = phase_invoke
    rescue ValidationError => e
      self.status = e.status if status == 200
      @errors = e.errors
    rescue StandardError => e
      self.status = 500 if status == 200
      @errors = e.errors
    end

    data
  end

  def invoke_block
    yield
  end

  # 存在チェック：リクエストパラメーター
  def phase_required_params
    required_param_names.each do |name|
      raise_error(:EXE_0001) unless request_params[name].present?
    end
  end

  # 存在チェック：リクエストボディ
  def phase_required_json_body
    return unless required_json_body_names.present?

    read_json_body
    required_json_body_names.each do |name|
      raise_error(:EXE_0001, name) unless @json_body.key?(name)
    end
  end

  # 認証チェック
  def phase_required_auth
    return unless required_auth?

    state = authenticate_request
    unless state[:authenticated]
      raise ValidationError.new(state[:errors], state[:status])
    end

    @current_user = state[:user]
  end

  # バリデーション
  def phase_validate; end

  # 実処理（子クラスで実装必須）
  def phase_invoke
    raise NotImplementedError, "You must implement #{self.class}##{__method__}"
  end

  # レスポンス
  def phase_response
    raise NotImplementedError, "You must implement #{self.class}##{__method__}"
  end

  def raise_error(code, *args)
    raise ValidationError, ErrorMessage.new(code, *args)
  end

  def required_auth?
    required_auth = self.class.get(:is_required_auth)
    required_auth.nil? ? true : required_auth
  end

  def required_param_names
    self.class.get(:required_param_names) || []
  end

  def required_json_body_names
    self.class.get(:required_json_body_names) || []
  end

  def read_json_body
    @json_body = (JSON.parse_symbol_safe(request.body.read) || {}) if @json_body.nil?
    @json_body
  end

  def health_data
    { status: "ok" }
  end

  private

    SECRET_KEY = Rails.application.credentials.secret_key_base
    JWT_ALGORITHM = "HS256"

    def authenticate_request
      token = _extract_token_from_header

      if token.nil?
        return { authenticated: false, errors: "トークンをリクエストヘッダーに指定してください", status: :unauthorized }
      end

      decoded = _valid_token?(token)
      if decoded.nil?
        return { authenticated: false, errors: "トークンが無効です", status: :unauthorized }
      end

      user = User.find_by(id: decoded[:user_id])
      if user.nil?
        return { authenticated: false, errors: "ユーザーが見つかりません", status: :unauthorized }
      end

      { authenticated: true, user: user  }
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
