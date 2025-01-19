require 'rails_helper'

describe 'DELETE /api/articles/:slug/comments/:id', type: :request do
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

  let!(:source_item) { FactoryBot.create(:article, user:) }

  let!(:other1) { FactoryBot.create(:user, prefix: 'other1') }
  let!(:other2) { FactoryBot.create(:user, prefix: 'other2') }
  let!(:other3) { FactoryBot.create(:user, prefix: 'other3') }

  let!(:comment01) { FactoryBot.create(:comment, prefix: '0-1', article: source_item, user: user) }
  let!(:comment11) { FactoryBot.create(:comment, prefix: '1-1', article: source_item, user: other1) }
  let!(:comment12) { FactoryBot.create(:comment, prefix: '1-2', article: source_item, user: other1) }
  let!(:comment21) { FactoryBot.create(:comment, prefix: '2-1', article: source_item, user: other2) }
  let!(:comment31) { FactoryBot.create(:comment, prefix: '3-1', article: source_item, user: other3) }

  context '未認証の場合' do
    it '認証エラーになる' do
      delete("/api/articles/#{source_item.slug}/comments/#{comment01.id}", headers: none_auth_headers)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context '自分のコメントの削除の場合' do
    it 'コメントが削除できる' do
      expect {
        delete("/api/articles/#{source_item.slug}/comments/#{comment01.id}", headers:)
      }.to change(Comment, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end

  context '他人のコメントの削除の場合' do
    it 'エラーになる' do
      delete("/api/articles/#{source_item.slug}/comments/#{comment11.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context '存在しない記事の場合' do
    it '正常終了する' do
      expect {
        delete("/api/articles/#{source_item.slug}/comments/fictitious_comment", headers:)
      }.to change(Comment, :count).by(0)
      expect(response).to have_http_status(:ok)
    end
  end
end
