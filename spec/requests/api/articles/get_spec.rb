require 'rails_helper'

describe 'GET /api/articles/:slug', type: :request do
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

  # 他のユーザー
  let!(:other1) {
    other1 = FactoryBot.create(:user, prefix: 'other1')
    expect(other1.valid?(context: :create)).to be_truthy
    other1
  }

  let!(:other2) {
    other2 = FactoryBot.create(:user, prefix: 'other2')
    expect(other2.valid?(context: :create)).to be_truthy
    other2
  }

  let!(:other3) {
    other3 = FactoryBot.create(:user, prefix: 'other3')
    expect(other3.valid?(context: :create)).to be_truthy
    other3
  }

  let!(:tags) { FactoryBot.create_list(:tag, 5) }

  let!(:source_item) {
    article = FactoryBot.create(:article, slug: 'source-item-slug', user:)
    FactoryBot.create(:article_tag, article: article, tag: tags[0])
    FactoryBot.create(:article_tag, article: article, tag: tags[1])

    FactoryBot.create(:favorite, article: article, user: other1)
    FactoryBot.create(:favorite, article: article, user: other2)

    article
  }

  # タグあり、お気に入りあり
  let!(:other1_item) {
    article = FactoryBot.create(:article, slug: 'other1-item-slug', user:)
    FactoryBot.create(:article_tag, article: article, tag: tags[2])

    FactoryBot.create(:favorite, article: article, user: other3)
    article
  }

  # タグあり、お気に入りなし
  let!(:other2_item) {
    article = FactoryBot.create(:article, slug: 'other2-item-slug', user:)
    article
  }

  # タグあり、お気に入りあり
  let!(:other3_item) {
    article = FactoryBot.create(:article, slug: 'other3-item-slug', user:)
    FactoryBot.create(:article_tag, article: article, tag: tags[3])
    FactoryBot.create(:article_tag, article: article, tag: tags[4])

    FactoryBot.create(:favorite, article: article, user: user)
    FactoryBot.create(:favorite, article: article, user: other3)
    article
  }



  context '正常なリクエストの場合' do
    it '記事が取得できる' do
      get("/api/articles/#{source_item.slug}", headers:)
      expect(response).to have_http_status(:ok)

      actual = JSON.parse(response.body)['article']
      expect(actual['id']).to eq(source_item.id)
      expect(actual['created_at']).to be nil # 含まれない
      expect(actual['updated_at']).to be nil # 含まれない

      expect(actual['slug']).to eq(source_item.slug)
      expect(actual['title']).to eq(source_item.title)
      expect(actual['description']).to eq(source_item.description)
      expect(actual['body']).to eq(source_item.body)

      expect(actual['author']['username']).to eq(user[:username])
      expect(actual['author']['boi']).to eq(user[:bio])
      expect(actual['author']['image']).to eq(user[:image])
      expect(actual['author']['email']).to eq(user[:email])

      expect(actual['tagList'][0]).to eq(tags[0].name)
      expect(actual['tagList'][1]).to eq(tags[1].name)

      expect(actual['favorited']).to eq(false)
      expect(actual['favoritesCount']).to eq(2)
    end
  end

  context 'タグなしお気に入りなしの場合' do
    it '記事が取得できる' do
      get("/api/articles/#{other2_item.slug}", headers:)
      expect(response).to have_http_status(:ok)

      actual = JSON.parse(response.body)['article']
      expect(actual['id']).to eq(other2_item.id)

      expect(actual['tagList']).to eq([])

      expect(actual['favorited']).to eq(false)
      expect(actual['favoritesCount']).to eq(0)
    end
  end

  context '自分がお気に入りにしている場合' do
    it '記事が取得できる' do
      get("/api/articles/#{other3_item.slug}", headers:)
      expect(response).to have_http_status(:ok)

      actual = JSON.parse(response.body)['article']
      expect(actual['id']).to eq(other3_item.id)

      expect(actual['tagList'][0]).to eq(tags[3].name)
      expect(actual['tagList'][1]).to eq(tags[4].name)

      expect(actual['favorited']).to eq(true)
      expect(actual['favoritesCount']).to eq(2)
    end
  end

  context '未認証の場合' do
    it "認証エラーになる" do
      get("/api/articles/#{source_item.slug}", headers: none_auth_headers) # トークンなし
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context '存在しない記事を更新しようとする' do
    it '404エラーになる' do
      get("/api/articles/non-existent-slug", headers:)
      expect(response).to have_http_status(:not_found)
    end
  end
end
