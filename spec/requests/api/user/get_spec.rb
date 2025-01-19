require 'rails_helper'

describe 'GET /aip/user', type: :request do
  it '未ログインの場合、401エラーになる' do
    get '/api/user'
    expect(response).to have_http_status(:unauthorized)
  end

  describe 'ログイン済の場合' do
    let(:user) {
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy
      user
    }
    let(:token) {
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['data']['user']
      expect(res['token']).not_to be nil

      res['token']
    }

    it 'ヘッダーが空の場合、401エラーになる' do
      get '/api/user', headers: { "Authorization": "" }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'ヘッダーの形式が不正な場合、401エラーになる' do
      get '/api/user', headers: { "Authorization": "#{token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'トークンの形式が不正な場合、401エラーになる' do
      get '/api/user', headers: { "Authorization": "Token #{token}a" } # トークンに文字列をくっつけて不正な形式にする
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "トークン有効期限" do
    # describe('トークンの有効期限切れチェック') do
    include ActiveSupport::Testing::TimeHelpers

    it 'トークンの有効期限切れの場合、401エラーになる' do
      # 準備
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['data']['user']
      expect(res['token']).not_to be nil

      token = res['token']

      # 実行
      travel 1.day do # 時間を有効期限まで進める
        get '/api/user', headers: { "Authorization": "Token #{token}" }

        # 検証
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'ヘッダーが正しく有効期限時刻ピッタリの場合、カレントユーザー情報が取得できる' do
      # 準備
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['data']['user']
      expect(res['token']).not_to be nil

      token = res['token']

      # 実行
      travel 1.day - 1.second do # 実処理（時間を有効期限の直前まで進める）
        get '/api/user', headers: { "Authorization": "Token #{token}" }

        # 検証
        expect(response).to have_http_status(:success)

        res =JSON.parse(response.body)['data']['user']
        expect(res['token']).to be nil # トークンは返却されない
        expect(res['bio']).to be nil
        expect(res['image']).to be nil

        expect(res['username']).to eq(user.username)
        expect(res['email']).to eq(user.email)
      end
    end
  end
end
