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
        othersArticle = FactoryBot.create(:article, slug: "sample-slug", user: other)

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
        othersArticle = FactoryBot.create(:article, slug: "sample-slug", user: other)
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
end
