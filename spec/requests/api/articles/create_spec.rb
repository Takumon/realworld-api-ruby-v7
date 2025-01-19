require 'rails_helper'

describe 'POST /api/articles', type: :request do
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


  context '未認証の場合' do
    it '認証エラーになる' do
      params = {
        article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body",
          tagList: [ "tag1", "tag2", "tag3", "tag4", "tag5" ]
        }
      }

      expect { post('/api/articles', params:, headers: none_auth_headers, as: :json) }.to change(Article, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context '正常なリクエストの場合' do
    let!(:params) {
      { article: {
        slug: "slug",
        title: "title",
        description: "description",
        body: "body",
        tagList: [ "tag1", "tag2", "tag3", "tag4", "tag5" ]
      } }
    }

    it '記事・タグ・タグの紐づきが登録される' do
      # expect { post('/api/articles', params:, headers:, as: :json) }.to change(Article, :count).by(1)
      post('/api/articles', params:, headers:, as: :json)
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
      expect(actual['tagList'].size).to eq(5)
      expect(actual['tagList'][0]).to eq('tag1')
      expect(actual['tagList'][1]).to eq('tag2')
      expect(actual['tagList'][2]).to eq('tag3')
      expect(actual['tagList'][3]).to eq('tag4')
      expect(actual['tagList'][4]).to eq('tag5')

      expect(actual['author']['username']).to eq(user[:username])
      expect(actual['author']['boi']).to eq(user[:bio])
      expect(actual['author']['image']).to eq(user[:image])
      expect(actual['author']['email']).to eq(user[:email])
    end
  end

  describe '入力チェック：タグ関連' do
    context 'タグが0文字の場合' do
      let!(:params) {
        { article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body",
          tagList: [ "tag1", "tag2", "tag3", "tag4", "t" * 0 ]
        } }
      }

      it '入力チェクエラーになる' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'タグが1文字の場合' do
      let!(:params) {
        { article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body",
          tagList: [ "tag1", "tag2", "tag3", "tag4", "t" * 1 ]
        } }
      }

      it '入力チェックエラーにならない' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:created)
      end
    end


    context 'タグが21文字の場合' do
      let!(:params) {
        { article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body",
          tagList: [ "tag1", "tag2", "tag3", "tag4", "t" * 21 ]
        } }
      }

      it '入力チェックエラーになる' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'タグが20文字の場合' do
      let!(:params) {
        { article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body",
          tagList: [ "tag1", "tag2", "tag3", "tag4", "t" * 20 ]
        } }
      }

      it '400エラーになる' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:created)
      end
    end

    context 'タグが6件以上の場合' do
      let!(:params) {
        { article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body",
          tagList: [ "tag1", "tag2", "tag3", "tag4", "tag5", "tag6" ]
        } }
      }

      it '400エラーになる' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'タグ名が重複している場合' do
      let!(:params) {
        { article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body",
          tagList: [ "tag1", "tag2", "tag3", "tag4", "tag1" ]
        } }
      }

      it "400エラーになる" do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe '入力チェク：タグ以外' do
    context '必須属性がない場合' do
      let!(:params) {
        { article: {
          # 未指定
        } }
      }

      it '入力チェックエラーになる' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context '最小桁数に満たない場合' do
      let!(:params) {
        { article: {
          slug: "a" * 0,
          title: "a" * 0,
          description: "a" * 0,
          body: "a" * 0
        } }
      }

      it '入力チェックエラーになる' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
        end
    end

    context '最小桁数の場合' do
      let!(:params) {
        { article: {
          slug: "a" * 1,
          title: "a" * 1,
          description: "a" * 1,
          body: "a" * 1
        } }
      }

      it '登録される' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:success)
        end
    end

    context '最大桁数の場合' do
      let!(:params) {
        { article: {
          slug: "a" * 100,
          title: "a" * 100,
          description: "a" * 500,
          body: "a" * 1000
        } }
      }

      it '登録される' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:success)
        end
    end

    context '最大桁数より大きい場合' do
      let!(:params) {
        { article: {
          slug: "a" * 101,
          title: "a" * 101,
          description: "a" * 501,
          body: "a" * 1001
        } }
      }

      it '入力チェックエラーになる' do
        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
        end
    end
  end

  describe '入力チェック：slugの一意性' do
    context '別ユーザーの記事に重複するslugがあり、自分の記事にない場合' do
      it '登録できる' do
        other = FactoryBot.create(:user, email: "other@sample.com")
        othersArticle = FactoryBot.create(:article, slug: "other-slug", user: other)

        params = { article: {
          slug: othersArticle.slug, # 他ユーザーの記事と同じslug
          title: "sample-title",
          description: "sample-description",
          body: "sample-body"
        } }

        expect { post('/api/articles', params:, headers:, as: :json) }.to change(Article, :count).by(1)
        expect(response).to have_http_status(:success)
      end
    end

    context '自分の記事に重複するslugがある場合' do
      it '入力チェックエラーになる' do
        other = FactoryBot.create(:user, email: "other@sample.com")
        othersArticle = FactoryBot.create(:article, slug: "other-slug", user: other)
        myArticle = FactoryBot.create(:article, slug: othersArticle.slug, user: user)

        params = { article: {
          slug: myArticle.slug, # 自分の記事と同じslug
          title: "sample-title",
          description: "sample-description",
          body: "sample-body"
        } }

        post('/api/articles', params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
