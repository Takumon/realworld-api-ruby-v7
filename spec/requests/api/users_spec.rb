require 'rails_helper'

describe '/aip/users' do
  describe 'ユーザー登録 POST /' do
    it 'ユーザーが登録される' do
      params = {
        user: {
          username: 'テスト用ユーザー名',
          email: 'test1@sample.com',
          password: 'testpassword'
        }
      }

      expect { post('/api/users', params:) }.to change(User, :count).by(1)
      expect(response).to have_http_status(:created)
      # DBに登録されたユーザー情報が正しいか確認
      user = params[:user]
      record = User.find_by(email: user[:email])
      expect(record.username).to eq(user[:username])
      expect(record.lock_version).to eq(0)
      expect(record.bio).to be nil
      expect(record.image).to be nil

      # パスワードがハッシュ化されているか確認
      expect(User.authenticate_by(email: user[:email], password: user[:password])).not_to be nil
    end

    it '重複するメールアドレスを登録しようとすると、400エラーになる' do
      user = FactoryBot.create(:user)
      expect(user).to be_valid

      params = {
        user: {
          username: 'テスト用ユーザー名',
          email: user.email,
          password: 'testpassword'
        }
      }

      expect { post('/api/users', params:) }.to change(User, :count).by(0)
      expect(response).to have_http_status(:bad_request)
    end


    describe '不正なリクエストパラメーターを指定すると400エラーになる' do
      it "必須チェック" do
        # 必須NG
        params = {
          user: {}
        }

        expect { post('/api/users', params:) }.to change(User, :count).by(0)
        expect(response).to have_http_status(:bad_request)
      end

      it '最小桁数' do
        # NG
        params = {
          user: {
            username: 'a' * 1,
            email: 'a' * 3,
            password: 'a' * 7
          }
        }

        expect { post('/api/users', params:) }.to change(User, :count).by(0)
        expect(response).to have_http_status(:bad_request)

        # OK
        params = {
          user: {
            username: 'a' * 2,
            email: 'a' * 4,
            password: 'a' * 8
          }
        }

        expect { post('/api/users', params:) }.to change(User, :count).by(1)
        expect(response).to have_http_status(:success)
      end

      it '最大桁数' do
        params = {
          user: {
            username: 'a' * 101,
            email: 'a' * 256,
            password: 'a' * 73
          }
        }

        expect { post('/api/users', params:) }.to change(User, :count).by(0)
        expect(response).to have_http_status(:bad_request)

        # 最大桁数OK
        params = {
          user: {
            username: 'a' * 100,
            email: 'a' * 255,
            password: 'a' * 72
          }
        }

        expect { post('/api/users', params:) }.to change(User, :count).by(1)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'ログイン POST /login' do
    it 'ログインできる' do
      user = FactoryBot.create(:user)
      expect(user).to be_valid

      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil
      expect(res['bio']).to be nil
      expect(res['image']).to be nil

      expect(res['username']).to eq(user.username)
      expect(res['email']).to eq(user.email)
    end

    describe 'ログインできない' do
      it 'メールアドレスが正しいが、パスワードが間違っている' do
        user = FactoryBot.create(:user)
        expect(user).to be_valid

        params = { user: { email: user.email, password: '間違っているパスワード' } }
        post('/api/users/login', params:)

        expect(response).to have_http_status(:unauthorized)
      end

      it 'メールアドレスが間違っている' do
        user = FactoryBot.create(:user)
        expect(user).to be_valid

        params = { user: { email: 'wrong-address@sample.com', password: user.password } }
        post('/api/users/login', params:)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

describe '/aip/user' do
  describe 'カレントユーザー情報取得 GET /' do
    include ActiveSupport::Testing::TimeHelpers

    it '未ログインの場合、401エラーになる' do
      get '/api/user'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'ヘッダーが空の場合、401エラーになる' do
      # 準備
      user = FactoryBot.create(:user)
      expect(user).to be_valid

      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      # 実処理
      get '/api/user', headers: { "Authorization": "" }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'ヘッダーの形式が不正な場合、401エラーになる' do
      # 準備
      user = FactoryBot.create(:user)
      expect(user).to be_valid

      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      # 実処理(valueの形式が不正)
      get '/api/user', headers: { "Authorization": "#{res['token']}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'トークンの形式が不正な場合、401エラーになる' do
      # 準備
      user = FactoryBot.create(:user)
      expect(user).to be_valid

      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      # 実処理(valueの形式が不正)
      get '/api/user', headers: { "Authorization": "Token #{res['token'] }a" } # トークンに文字列をくっつけて不正な形式にする
      expect(response).to have_http_status(:unauthorized)
    end


    it 'トークンの有効期限切れの場合、401エラーになる' do
      # 準備
      user = FactoryBot.create(:user)
      expect(user).to be_valid

      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      # 実処理（時間を有効期限まで進める）
      travel 1.day do
        get '/api/user', headers: { "Authorization": "Token #{res['token']}" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'ヘッダーが正しく有効期限時刻ピッタリの場合、カレントユーザー情報が取得できる' do
      # 準備
      user = FactoryBot.create(:user)
      expect(user).to be_valid

      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      # 実処理（時間を有効期限の直前まで進める）
      travel 1.day - 1.second do
        get '/api/user', headers: { "Authorization": "Token #{res['token']}" }
        expect(response).to have_http_status(:success)

        res =JSON.parse(response.body)['user']
        expect(res['token']).to be nil # トークンは返却されない
        expect(res['bio']).to be nil
        expect(res['image']).to be nil

        expect(res['username']).to eq(user.username)
        expect(res['email']).to eq(user.email)
      end
    end
  end
end
