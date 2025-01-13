require 'rails_helper'

describe '/api/profiles', type: :request do
  # ログインユーザー
  let!(:user) {
    user = FactoryBot.create(:user, prefix: 'mine')
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
    res =JSON.parse(response.body)['user']
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

  # 他者
  let!(:other) {
    user = FactoryBot.create(:user, prefix: 'other')
    expect(user.valid?(context: :create)).to be_truthy
    user
  }



  describe "詳細 GET /:username" do
    context "フォローしていないユーザーの場合" do
      it "プロフィールが取得できる" do
        get "/api/profiles/#{other.username}", headers:, as: :json
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)['user']
        expect(res['username']).to eq(other.username)
        expect(res['following']).to eq(false) # フォローしていない
      end
    end

    context "フォローしているユーザーの場合" do
      it "プロフィールが取得できる" do
        other2 = FactoryBot.create(:user, prefix: 'other2')
        Relationship.create(follower: user, followed: other2)

        get "/api/profiles/#{other2.username}", headers:, as: :json
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)['user']
        expect(res['username']).to eq(other2.username)
        expect(res['following']).to eq(true) # フォローしている
      end
    end

    context "存在しないユーザーの場合" do
      it "404エラーになる" do
        get "/api/profiles/fictitious_user_naem", headers:, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未認証の場合" do
      it "認証エラーになる" do
        get "/api/profiles/#{other.username}", headers: none_auth_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end



  describe "フォロー POST /:username/follow" do
    context "フォローしていないユーザーの場合" do
      it "フォローできる" do
        expect {
          post "/api/profiles/#{other.username}/follow", headers:, as: :json
        }.to change(Relationship, :count).by(1)
        expect(response).to have_http_status(:ok)
      end
    end

    context "既にフォローしている場合" do
      it "フォロー処理は正常に終了する" do
        other2 = FactoryBot.create(:user, prefix: 'other2')
        Relationship.create(follower: user, followed: other2)

        expect {
          post "/api/profiles/#{other2.username}/follow", headers:, as: :json
        }.to change(Relationship, :count).by(0) # 数は変わらない
        expect(response).to have_http_status(:ok)
      end
    end

    context "フォローするユーザー名が存在しない場合" do
      it "404エラーになる" do
        post "/api/profiles/fictitious_user_name/follow", headers:, as: :json
        expect(response).to have_http_status(:not_found)
        errors = JSON.parse(response.body)["errors"]
        expect(errors[0]['username']).to eq('存在しないユーザー名です')
      end
    end

    context "未認証の場合" do
      it "認証エラーになる" do
        post "/api/profiles/#{other.username}/follow", headers: none_auth_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end



  describe "フォロー解除 DELETE /:username/follow" do
    context "フォローしていないユーザーの場合" do
      it "フォロー解除処理は正常に終了する" do
        expect {
          delete "/api/profiles/#{other.username}/follow", headers:, as: :json
        }.to change(Relationship, :count).by(0) # 数は変わらない
        expect(response).to have_http_status(:ok)
      end
    end

    context "フォローしているユーザーの場合" do
      it "フォロー解除できる" do
        other2 = FactoryBot.create(:user, prefix: 'other2')
        Relationship.create(follower: user, followed: other2)

        expect {
          delete "/api/profiles/#{other2.username}/follow", headers:, as: :json
        }.to change(Relationship, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end
    end

    context "存在しないユーザーの場合" do
      it "404エラーになる" do
        expect {
          delete "/api/profiles/fictitious_user_name/follow", headers:, as: :json
        }.to change(Relationship, :count).by(0) # 数は変わらない
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未認証の場合" do
      it "認証エラーになる" do
        delete "/api/profiles/#{other.username}/follow", headers: none_auth_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
