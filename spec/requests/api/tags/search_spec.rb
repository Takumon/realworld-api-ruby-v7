require 'rails_helper'

describe 'GET /api/tags', type: :request do
  # ログインユーザー
  let!(:user) {
    user = FactoryBot.create(:user)
    expect(user.valid?(context: :create)).to be_truthy
    user
  }

  # 未ログイン検証用のヘッダー
  let!(:none_auth_headers) {
    {
      "CONTENT_TYPE": "application/json",
      "ACCEPT": "application/json"
    }
  }

  # 認証トークン
  let!(:token) {
    params = { user: { email: user.email, password: user.password } }
    post('/api/users/login', params:, headers: none_auth_headers, as: :json)

    expect(response).to have_http_status(:success)
    res =JSON.parse(response.body)['data']['user']
    expect(res['token']).not_to be nil

    res['token']
  }

  # 認証情報付きヘッダー
  let!(:headers) {
    {
      "Authorization": "Token #{token}",
      **none_auth_headers
    }
  }

  context "未認証の場合" do
    it "タグ一覧を取得できる" do
      tags = FactoryBot.create_list(:tag, 4)

      get('/api/tags', headers: none_auth_headers)
      expect(response).to have_http_status(:success)
      res = JSON.parse(response.body)['data']
      expect(res['tags']).to eq(tags.map(&:name)) # ソートの順は？
    end
  end

  context "正常なリクエストの場合" do
    it "タグ一覧を取得できる" do
      tags = FactoryBot.create_list(:tag, 4)

      get('/api/tags', headers:)
      expect(response).to have_http_status(:success)
      res = JSON.parse(response.body)['data']
      expect(res['tags']).to eq(tags.map(&:name)) # ソートの順は？
    end
  end

  context "タグが0件の場合" do
    it "タグ一覧を取得できる" do
      get('/api/tags', headers:)
      expect(response).to have_http_status(:success)
      res = JSON.parse(response.body)['data']
      expect(res['tags'].size).to eq(0)
    end
  end
end
