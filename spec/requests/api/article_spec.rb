require 'rails_helper'

describe '/api/articles', type: :request do
  describe "記事作成 POST /" do
    # ログインユーザー
    let(:user) {
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy
      user
    }

    # 認証トークン
    let(:token) {
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      res['token']
    }

    it '正常なリクエストの場合、ステータスコード 200 が返ること' do
      headers = { "Authorization": "Token #{token}" }

      params = {
        article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body"
        }
      }

      expect { post('/api/articles', params:, headers:) }.to change(Article, :count).by(1)
      expect(response).to have_http_status(:success)
      actual = JSON.parse(response.body)['article']
      input = params[:article]
      expect(actual['id']).not_to be nil
      expect(actual['created_at']).to be nil
      expect(actual['updated_at']).to be nil

      expect(actual['slug']).to eq(input[:slug])
      expect(actual['title']).to eq(input[:title])
      expect(actual['description']).to eq(input[:description])
      expect(actual['body']).to eq(input[:body])

      expect(actual['author']['username']).to eq(user[:username])
      expect(actual['author']['boi']).to eq(user[:bio])
      expect(actual['author']['image']).to eq(user[:image])
      expect(actual['author']['email']).to be nil
    end

    describe '不正なリクエストパラメーターを指定すると400エラーになる' do
      it '必須チェック' do
        # NG
        headers = { "Authorization": "Token #{token}" }

        params = {
          article: {}
        }

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        params = {
          article: {
            slug: "slug",
            title: "title",
            description: "description",
            body: "body"
          }
        }

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:success)
      end

      it '最小桁数チェック' do
        # NG
        headers = { "Authorization": "Token #{token}" }

        params = {
          article: {
            slug: "a" * 0,
            title: "a" * 0,
            description: "a" * 0,
            body: "a" * 0
          }
        }

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        params = {
          article: {
            slug: "a" * 1,
            title: "a" * 1,
            description: "a" * 1,
            body: "a" * 1
          }
        }

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:success)
      end

      it '最大桁数チェック' do
        # NG
        headers = { "Authorization": "Token #{token}" }

        params = {
          article: {
            slug: "a" * 101,
            title: "a" * 101,
            description: "a" * 501,
            body: "a" * 1001
          }
        }

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        params = {
          article: {
            slug: "a" * 100,
            title: "a" * 100,
            description: "a" * 500,
            body: "a" * 1000
          }
        }

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'slugの一意性' do
      it '別ユーザーで同じslugの記事があっても正常に登録できる' do
        other = FactoryBot.create(:user, email: "other@sample.com")
        othersArticle = FactoryBot.create(:article, slug: "other-slug", user: other)

        headers = { "Authorization": "Token #{token}" }

        params = {
          article: {
            slug: othersArticle.slug, # 他ユーザーの記事と同じslug
            title: "sample-title",
            description: "sample-description",
            body: "sample-body"
          }
        }

        expect { post('/api/articles', params:, headers:) }.to change(Article, :count).by(1)
        expect(response).to have_http_status(:success)
      end

      it '同じユーザーで同じslugの記事がある場合400エラーになる' do
        other = FactoryBot.create(:user, email: "other@sample.com")
        othersArticle = FactoryBot.create(:article, slug: "other-slug", user: other)
        myArticle = FactoryBot.create(:article, slug: othersArticle.slug, user: user)

        headers = { "Authorization": "Token #{token}" }

        params = {
          article: {
            slug: myArticle.slug, # 自分の記事と同じslug
            title: "sample-title",
            description: "sample-description",
            body: "sample-body"
          }
        }

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "記事作成 UPDATE /" do
    # ログインユーザー
    let(:user) {
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy
      user
    }

    let(:source_item) { FactoryBot.create(:article, slug: 'source-item-slug', user:) }

    # 他のユーザー
    let(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let(:other_item) { FactoryBot.create(:article, slug: 'other-item-slug', user: other_user) }

    # 認証用リクエストヘッダー
    let(:headers) {
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      { "Authorization": "Token #{res['token']}" }
    }


    it '正常なリクエストの場合、ステータスコード 200 が返ること' do
      params = {
        article: {
          title: source_item.title + " updated title",
          description: source_item.description + " updated description",
          body: source_item.body + "updated body"
        }
      }

      put("/api/articles/#{source_item.slug}", params:, headers:)
      expect(response).to have_http_status(:ok)
      actual = JSON.parse(response.body)['article']
      input = params[:article]
      expect(actual['title']).to eq(input[:title])
      expect(actual['description']).to eq(input[:description])
      expect(actual['body']).to eq(input[:body])
    end

    it "未認証の場合、401エラーになる" do
      params = {
        article: {
          title: source_item.title + " updated title",
          description: source_item.description + " updated description",
          body: source_item.body + "updated body"
        }
      }

      put("/api/articles/#{source_item.slug}", params:) # トークンは未指定
      expect(response).to have_http_status(:unauthorized)
    end

    it '存在しない記事を更新しようとすると404エラーになる' do
      params = {
        article: {
          title: source_item.title + " updated title",
          description: source_item.description + " updated description",
          body: source_item.body + "updated body"
        }
      }

      put("/api/articles/non-existent-slug", params:, headers:)
      expect(response).to have_http_status(:not_found)
    end

    it '他ユーザーの記事を更新しようとすると404エラーになる' do
      params = {
        article: {
          title: other_item.title + " updated title",
          description: other_item.description + " updated description",
          body: other_item.body + "updated body"
        }
      }

      put("/api/articles/#{other_item.slug}", params:, headers:)
      expect(response).to have_http_status(:not_found)
    end

    it '楽観排他はなし（連続で更新できる）' do
      params = {
        article: {
          title: source_item.title + " updated title",
          description: source_item.description + " updated description",
          body: source_item.body + "updated body"
        }
      }

      put("/api/articles/#{source_item.slug}", params:, headers:)
      expect(response).to have_http_status(:ok)

      # 連続で更新
      put("/api/articles/#{source_item.slug}", params:, headers:)
      expect(response).to have_http_status(:ok)
    end

    describe '不正なリクエストパラメーターを指定すると400エラーになる' do
      it '更新対象項目を何も指定しない場合、400エラーになる' do
        params = {
          article: {
            # 空
          }
        }

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:bad_request)
      end

      it '最低桁数チェック' do
        # NG
        params = {
          article: {
            title: "a" * 0,
            description: "a" * 0,
            body: "a" * 0
          }
        }

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        params = {
          article: {
            title: "a" * 1,
            description: "a" * 1,
            body: "a" * 1
          }
        }

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:success)
      end

      it '最大桁数チェック' do
        # NG
        params = {
          article: {
            title: "a" * 101,
            description: "a" * 501,
            body: "a" * 1001
          }
        }

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        params = {
          article: {
            title: "a" * 100,
            description: "a" * 500,
            body: "a" * 1000
          }
        }

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "記事削除 DELETE /" do
    # ログインユーザー
    let(:user) {
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy
      user
    }

    let(:source_item) { FactoryBot.create(:article, user:) }

    # 他のユーザー
    let(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let(:other_item) { FactoryBot.create(:article, slug: 'other-item-slug', user: other_user) }

    # 認証用リクエストヘッダー
    let(:headers) {
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      { "Authorization": "Token #{res['token']}" }
    }

    it '正常なリクエストの場合、ステータスコード 200 が返ること' do
      delete("/api/articles/#{source_item.slug}", headers:)
      expect(response).to have_http_status(:ok)
      expect(Article.exists?(source_item.id)).to be_falsey # 存在しない
    end

    it "未認証の場合、401エラーになる" do
      # トークンは未指定
      delete("/api/articles/#{source_item.slug}")
      expect(response).to have_http_status(:unauthorized)
      expect(Article.exists?(source_item.id)).to be_truthy # 存在する
    end

    it '存在しない記事を更新しようとすると404エラーになる' do
      delete("/api/articles/non-existent-slug", headers:)
      expect(response).to have_http_status(:not_found)
    end

    it '他ユーザーの記事を更新しようとすると404エラーになる' do
      delete("/api/articles/#{other_item.slug}", headers:)
      expect(response).to have_http_status(:not_found)
      expect(Article.exists?(other_item.id)).to be_truthy # 存在する
    end
  end

  describe "記事取得 GET /" do
    # ログインユーザー
    let(:user) {
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy
      user
    }

    let(:source_item) { FactoryBot.create(:article, slug: 'source-item-slug', user:) }

    # 他のユーザー
    let(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let(:other_item) { FactoryBot.create(:article, slug: 'other-item-slug', user: other_user) }

    # 認証用リクエストヘッダー
    let(:headers) {
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      { "Authorization": "Token #{res['token']}" }
    }

    it '正常なリクエストの場合、ステータスコード 200 が返ること' do
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
      expect(actual['author']['email']).to be nil # emailは含まれない
    end

    it "未認証の場合、401エラーになる" do
      # トークンは未指定
      get("/api/articles/#{source_item.slug}")
      expect(response).to have_http_status(:unauthorized)
    end

    it '存在しない記事を更新しようとすると404エラーになる' do
      get("/api/articles/non-existent-slug", headers:)
      expect(response).to have_http_status(:not_found)
    end

    it '他ユーザーの記事を更新しようとすると404エラーになる' do
      get("/api/articles/#{other_item.slug}", headers:)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "記事一覧取得 GET /" do
    # ログインユーザー
    let(:user) {
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy
      user
    }

    let(:source_items) { FactoryBot.create_list(:article, 100, prefix: 'mine', user:) }

    # 他のユーザー
    let(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let(:other_items) { FactoryBot.create_list(:article, 100, prefix: 'mine', user: other_user) }

    # 認証用リクエストヘッダー
    let(:headers) {
      params = { user: { email: user.email, password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:success)
      res =JSON.parse(response.body)['user']
      expect(res['token']).not_to be nil

      { "Authorization": "Token #{res['token']}" }
    }

    it "正常なリクエストの場合、ステータスコード 200 が返ること" do
    end
  end
end
