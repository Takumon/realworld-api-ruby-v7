require 'rails_helper'

describe 'PUT /aip/user', type: :request do
  it '未ログインの場合、401エラーになる' do
    put '/api/user'
    expect(response).to have_http_status(:unauthorized)
  end

  it "楽観排他制御エラー" do
    # 準備
    user = FactoryBot.create(:user)
    expect(user.valid?(context: :create)).to be_truthy

    params = { user: { email: user.email, password: user.password } }
    post('/api/users/login', params:)

    expect(response).to have_http_status(:success)
    res =JSON.parse(response.body)['user']
    expect(res['token']).not_to be nil

    token = res['token']

    # 1回目の更新
    params = {
      user: {
        email: 'a' * 4,
        bio: 'a' * 1,
        image: 'a' * 1,
        lock_version: user.lock_version
      }
    }

    put('/api/user', params:, headers: { Authorization: "Token #{token}" })
    expect(response).to have_http_status(:success)

    # 2回目の更新
    put('/api/user', params:, headers: { Authorization: "Token #{token}" })
    expect(response).to have_http_status(:conflict)
  end

  describe '不正なリクエストパラメーターを指定すると400エラーになる' do
    let (:user) { FactoryBot.create(:user, email: 'test1@sample.com') }
    let (:other) { FactoryBot.create(:user, email: 'test2@sample.com') }
    let (:token) {
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      res['token']
    }

    it "必須チェック" do
      # NG
      params = {
        user: {}
      }

      put('/api/user', params:, headers: { Authorization: "Token #{token}" })
      expect(response).to have_http_status(:bad_request)
    end

    it "最低桁数チェック" do
      # NG
      params = {
        user: {
          email: 'a' * 3,
          bio: 'a' * 0,
          image: 'a' * 0,
          lock_version: user.lock_version
        }
      }

      put('/api/user', params:, headers: { Authorization: "Token #{token}" })
      expect(response).to have_http_status(:bad_request)

      # OK
      params = {
        user: {
          email: 'a' * 4,
          bio: 'a' * 1,
          image: 'a' * 1,
          lock_version: user.lock_version
        }
      }

      put('/api/user', params:, headers: { Authorization: "Token #{token}" })
      expect(response).to have_http_status(:success)
    end

    it "最大桁数チェック" do
      # NG
      params = {
        user: {
          email: 'a' * 256,
          bio: 'a' * 501,
          image: 'a' * 501,
          lock_version: user.lock_version
        }
      }

      put('/api/user', params:, headers: { Authorization: "Token #{token}" })
      expect(response).to have_http_status(:bad_request)

      # OK
      params = {
        user: {
          email: 'a' * 255,
          bio: 'a' * 500,
          image: 'a' * 500,
          lock_version: user.lock_version
        }
      }

      put('/api/user', params:, headers: { Authorization: "Token #{token}" })
      expect(response).to have_http_status(:success)
    end


    it "最大桁数チェック" do
      # NG
      params = {
        user: {
          email: 'a' * 256,
          bio: 'a' * 501,
          image: 'a' * 501,
          lock_version: user.lock_version
        }
      }

      put('/api/user', params:, headers: { Authorization: "Token #{token}" })
      expect(response).to have_http_status(:bad_request)

      # OK
      params = {
        user: {
          email: 'a' * 255,
          bio: 'a' * 500,
          image: 'a' * 500,
          lock_version: user.lock_version
        }
      }

      put('/api/user', params:, headers: { Authorization: "Token #{token}" })
      expect(response).to have_http_status(:success)
    end

    describe 'メールアドレス重複チェック' do
      it '他のユーザーのメールアドレスで更新しようとすると、400エラーになる' do
        params = {
          user: {
            email: other.email, # 他のユーザーのメールアドレス
            bio: 'a' * 500,
            image: 'a' * 500,
            lock_version: user.lock_version
          }
        }

        put('/api/user', params:, headers: { Authorization: "Token #{token}" })
        expect(response).to have_http_status(:bad_request)
      end

      it '自分のメールアドレスで更新しようとすると、成功する' do
        params = {
          user: {
            email: user.email, # 自分のメールアドレス
            bio: 'a' * 500,
            image: 'a' * 500,
            lock_version: user.lock_version
          }
        }

        put('/api/user', params:, headers: { Authorization: "Token #{token}" })
        expect(response).to have_http_status(:success)
      end
    end
  end
end
