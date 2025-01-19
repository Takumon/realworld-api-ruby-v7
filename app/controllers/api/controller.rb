class Api::Controller < ApplicationController
  def phase_response(data, status) # TODO エラーハンドリング実装後に、引数statusを削除する
    render json: data,
          status: status,
          content_type: "application/json",
          charset: "utf-8"
  end
end
