require 'rails_helper'

describe 'POST /api/articles/:slug/comments/', type: :request do
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

  let!(:source_item) { FactoryBot.create(:article, user:) }

  let!(:other1) { FactoryBot.create(:user, prefix: 'other1') }
  let!(:other2) { FactoryBot.create(:user, prefix: 'other2') }
  let!(:other3) { FactoryBot.create(:user, prefix: 'other3') }

  let!(:comment11) { FactoryBot.create(:comment, prefix: '1-1', article: source_item, user: other1) }
  let!(:comment12) { FactoryBot.create(:comment, prefix: '1-2', article: source_item, user: other1) }
  let!(:comment21) { FactoryBot.create(:comment, prefix: '2-1', article: source_item, user: other2) }
  let!(:comment31) { FactoryBot.create(:comment, prefix: '3-1', article: source_item, user: other3) }

  context '正常なリクエストの場合' do
    it 'コメントが登録できる' do
      params = {
        comment: {
          body: 'コメント本文'
        }
      }

      expect {
        post("/api/articles/#{source_item.slug}/comments", params:, headers:, as: :json)
      }.to change(Comment, :count).by(1)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)['data']['comment']
      expect(res['body']).to eq(params[:comment][:body])
    end
  end

  context '同じ記事に同じ人が複数コメントを登録しようとする場合' do
    it 'コメントが登録できる' do
      # 1回目
      params = {
        comment: {
          body: 'コメント本文1'
        }
      }

      expect {
        post("/api/articles/#{source_item.slug}/comments", params:, headers:, as: :json)
      }.to change(Comment, :count).by(1)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)['data']['comment']
      expect(res['body']).to eq(params[:comment][:body])

      # 2回目
      params = {
        comment: {
          body: 'コメント本文2'
        }
      }

      expect {
        post("/api/articles/#{source_item.slug}/comments", params:, headers:, as: :json)
      }.to change(Comment, :count).by(1)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)['data']['comment']
      expect(res['body']).to eq(params[:comment][:body])
    end
  end

  context '未認証の場合' do
    it '認証エラーになる' do
      params = {
        comment: {
          body: 'コメント本文'
        }
      }

      post("/api/articles/fictitious_article/comments", params:, headers: none_auth_headers, as: :json)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context '存在しない記事の場合' do
    it '404エラーになる' do
      params = {
        comment: {
          body: 'コメント本文'
        }
      }

      post("/api/articles/fictitious_article/comments", params:, headers:, as: :json)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '入力チェック' do
    context '必須パラメーターがない場合' do
      it '入力チェックエラーになる' do
        params = {
          comment: {
            # body: 'コメント本文'
          }
        }

        post("/api/articles/#{source_item.slug}/comments", params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context '最小桁数未満の場合' do
      it '入力チェックエラーになる' do
        params = {
          comment: {
            body: 'a' * 0
          }
        }

        post("/api/articles/#{source_item.slug}/comments", params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context '最小桁数の場合' do
      it '登録できる' do
        params = {
          comment: {
            body: 'a' * 1
          }
        }

        post("/api/articles/#{source_item.slug}/comments", params:, headers:, as: :json)
        expect(response).to have_http_status(:ok)
      end
    end

    context '最大桁数の場合' do
      it '登録できる' do
        params = {
          comment: {
            body: 'a' * 200
          }
        }

        post("/api/articles/#{source_item.slug}/comments", params:, headers:, as: :json)
        expect(response).to have_http_status(:ok)
      end
    end

    context '最大桁数より大きい場合' do
      it '入力チェックエラーになる' do
        params = {
          comment: {
            body: 'a' * 201
          }
        }

        post("/api/articles/#{source_item.slug}/comments", params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
