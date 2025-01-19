require 'rails_helper'

describe 'DELETE /api/articles/:slug', type: :request do
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



  # 他のユーザー
  let!(:other1) {
    other1 = FactoryBot.create(:user, email: 'other1@sample.com')
    expect(other1.valid?(context: :create)).to be_truthy
    other1
  }

  let!(:other2) {
    other2 = FactoryBot.create(:user, email: 'other2@sample.com')
    expect(other2.valid?(context: :create)).to be_truthy
    other2
  }

  let!(:other3) {
    other3 = FactoryBot.create(:user, email: 'other3@sample.com')
    expect(other3.valid?(context: :create)).to be_truthy
    other3
  }

  let!(:source_item) {
    FactoryBot.create(:article, user:)
  }

  let(:attached_tags) {
    tags = FactoryBot.create_list(:tag, 3)
    FactoryBot.create(:article_tag, article: source_item, tag: tags[0])
    FactoryBot.create(:article_tag, article: source_item, tag: tags[1])
    FactoryBot.create(:article_tag, article: source_item, tag: tags[2])
    tags
  }

  let(:attached_favorites) {
    result = []
    result << FactoryBot.create(:favorite, article: source_item, user: other1)
    result << FactoryBot.create(:favorite, article: source_item, user: other2)
    result
  }


  let!(:other_item) { FactoryBot.create(:article, slug: 'other-item-slug', user: other1) }

  context '正常なリクエストの場合' do
    it '削除される' do
      expect {
        delete("/api/articles/#{source_item.slug}", headers:)
      }.to change(Article, :count).by(-1)
      .and change(ArticleTag, :count).by(-1 * attached_tags.size)
      .and change(Tag, :count).by(0) # タグ自体は削除されない
      .and change(Favorite, :count).by(-1 * attached_favorites.size)

      expect(response).to have_http_status(:ok)
      expect(Article.exists?(source_item.id)).to be_falsey # 存在しない
    end
  end

  context '未認証の場合' do
    it "認証エラーになる" do
      expect {
        delete("/api/articles/#{source_item.slug}", headers: none_auth_headers) # トークン無しのヘッダー
      }.to change(Article, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context '存在しない記事を更新しようとする' do
    it '404エラーになる' do
      expect {
        delete("/api/articles/non-existent-slug", headers:)
      }.to change(Article, :count).by(0)
      expect(response).to have_http_status(:not_found)
    end
  end

  context '他ユーザーの記事を更新しようとする' do
    it '404エラーになる' do
      expect {
        delete("/api/articles/#{other_item.slug}", headers:)
      }.to change(Article, :count).by(0)
      expect(response).to have_http_status(:not_found)
      expect(Article.exists?(other_item.id)).to be_truthy # 存在する
    end
  end
end
