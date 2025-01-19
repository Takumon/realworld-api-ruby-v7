require 'rails_helper'

describe 'DELETE /api/articles/:slug/favorite', type: :request do
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

  let!(:source_item) {
    FactoryBot.create(:article, user:)
  }

  # 他のユーザー1
  let!(:other1) {
    other_user = FactoryBot.create(:user, prefix: 'other1')
    expect(other_user.valid?(context: :create)).to be_truthy
    other_user
  }


  # 他のユーザー2
  let!(:other2) {
    other_user = FactoryBot.create(:user, prefix: 'other2')
    expect(other_user.valid?(context: :create)).to be_truthy
    other_user
  }

  context '未認証の場合' do
    it '認証エラーになる' do
      expect {
        delete("/api/articles/#{source_item.slug}/favorite", headers: none_auth_headers, as: :json)
      }.to change(Favorite, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context '正常なリクエストの場合' do
    it 'お気に入りが登録が解除される' do
      Favorite.create(user: user, article: source_item)
      Favorite.create(user: other1, article: source_item)

      expect {
        delete("/api/articles/#{source_item.slug}/favorite", headers:, as: :json)
      }.to change(Favorite, :count).by(-1)
      expect(response).to have_http_status(:success)
      res = JSON.parse(response.body)['article']
      expect(res['favorited']).to eq(false)
      expect(res['favoritesCount']).to eq(1)
    end
  end

  context 'お気に入り登録がされていない場合' do
    it "正常に終了する" do
      # Favorite.create(user: user, article: source_item) # 登録されていない
      Favorite.create(user: other1, article: source_item)

      expect {
        delete("/api/articles/#{source_item.slug}/favorite", headers:, as: :json)
      }.to change(Favorite, :count).by(0)
      expect(response).to have_http_status(:success)
      res = JSON.parse(response.body)['article']
      expect(res['favorited']).to eq(false)
      expect(res['favoritesCount']).to eq(1)
    end
  end

  context '存在しないユーザーの場合' do
    it '404エラーになる' do
      delete("/api/articles/fictitious_user/favorite", headers:, as: :json)
      expect(response).to have_http_status(:not_found)
    end
  end
end
