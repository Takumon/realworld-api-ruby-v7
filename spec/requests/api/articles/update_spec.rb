require 'rails_helper'

describe 'PUT /api/articles/:slug', type: :request do
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



  let!(:tags) { FactoryBot.create_list(:tag, 10) }

  # 記事（タグなし）
  let!(:source_item) {
    FactoryBot.create(
      :article, slug: 'source-item-slug',
      user: user,
    )
  }

  describe "タグ関連" do
    context '存在するタグに記事を紐づける場合' do
      let!(:params) {
        { article: {
          tagList: [ tags[0].name ]
        } }
      }

      it "タグは登録されず、タグの紐づけが登録される" do
        expect {
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        }.to change(Article, :count).by(0)
          .and change(ArticleTag, :count).by(1)
          .and change(Tag, :count).by(0)

        expect(response).to have_http_status(:ok)

        actual = JSON.parse(response.body)['article']
        expect(actual['tagList'].size).to eq(1)
        expect(actual['tagList'][0]).to eq(tags[0].name)
      end
    end

    context '存在するタグに記事を紐づける場合' do
      let!(:new_tag_name) {
        'new_tag_name'
      }

      let!(:params) {
        { article: {
          tagList: [ new_tag_name ]
        } }
      }

      it "タグとタグの紐づけが登録される" do
        expect {
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        }.to change(Article, :count).by(0)
          .and change(ArticleTag, :count).by(1)
          .and change(Tag, :count).by(1) # タグも新たに登録

        expect(response).to have_http_status(:ok)

        actual = JSON.parse(response.body)['article']
        expect(actual['tagList'].size).to eq(1)
        expect(actual['tagList'][0]).to eq(new_tag_name)
      end
    end

    context 'タグの紐づきがある場合、タグの紐づきにから配列を指定した場合' do
      it "タグの紐づきを削除ができる" do
        new_tag_name = 'new_tag_name'

        # 準備（追加）
        params = { article: {
          tagList: [ new_tag_name ]
        } }

        put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        expect(response).to have_http_status(:ok)

        # 実行（削除）
        params = { article: {
          tagList: [] # 空配列
        } }

        expect {
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        }.to change(Article, :count).by(0)
        .and change(ArticleTag, :count).by(-1)
        .and change(Tag, :count).by(0) # タグは削除されない
        expect(response).to have_http_status(:ok)

        actual = JSON.parse(response.body)['article']
        expect(actual['tagList'].size).to eq(0)
      end
    end

    context 'タグの紐づきがある場合、タグの紐づきを指定しない場合' do
      it "タグの紐づきは削除されない" do
        new_tag_name = 'new_tag_name'
        # 準備（追加）
        params = { article: {
          tagList: [ new_tag_name ]
        } }

        expect {
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        }.to change(Article, :count).by(0)
        .and change(ArticleTag, :count).by(1)
        .and change(Tag, :count).by(1)

        expect(response).to have_http_status(:ok)

        actual = JSON.parse(response.body)['article']
        expect(actual['tagList'].size).to eq(1)
        expect(actual['tagList'][0]).to eq(new_tag_name)

        # 実行（削除）
        params = { article: {
          body: source_item.body
          # tagList未指定
        } }

        expect {
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        }.to change(Article, :count).by(0)
        .and change(ArticleTag, :count).by(0)  # 削除されない
        .and change(Tag, :count).by(0)
        expect(response).to have_http_status(:ok)

        actual = JSON.parse(response.body)['article']
        expect(actual['tagList'].size).to eq(1)
      end
    end
  end

  describe "タグ以外" do
    let!(:tags) { FactoryBot.create_list(:tag, 10) }

    let!(:source_item) {
      article = FactoryBot.create(
        :article, slug: 'source-item-slug',
        user: user,
      )

      # 紐づきのpositionはタグの並び順と一致するように登録
      tags[0..4].each_with_index do |tag, i|
        FactoryBot.create(:article_tag, article: article, tag: tag, position: i)
      end

      article.reload # 追加されたタグの紐づきを反映
    }

    # 他のユーザー
    let!(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let!(:other_item) {
      article = FactoryBot.create(
        :article, slug: 'other-item-slug',
        user: other_user,
      )

      # 紐づきのpositionはタグの並び順と一致するように登録
      tags[5..9].each_with_index do |tag, i|
        FactoryBot.create(:article_tag, article: article, tag: tag, position: i)
      end

      article.reload # 追加されたタグの紐づきを反映
    }

    context '正常なリクエストの場合' do
      let!(:params) {
        { article: {
          title: source_item.title + " updated title",
          description: source_item.description + " updated description",
          body: source_item.body + "updated body"
        } }
      }

      it '記事が更新される' do
        expect {
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        }.to change(Article, :count).by(0)
        .and change(ArticleTag, :count).by(0)
        .and change(Tag, :count).by(0)

        expect(response).to have_http_status(:ok)
        actual = JSON.parse(response.body)['article']
        input = params[:article]
        expect(actual['title']).to eq(input[:title])
        expect(actual['description']).to eq(input[:description])
        expect(actual['body']).to eq(input[:body])
      end
    end

    context '未認証の場合' do
      it "認証エラーになる" do
        params = {
          article: {
            title: source_item.title + " updated title",
            description: source_item.description + " updated description",
            body: source_item.body + "updated body"
          }
        }

        put("/api/articles/#{source_item.slug}", params:, as: :json, headers: none_auth_headers)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context '存在しない記事を更新しようとする' do
      it '404エラーになる' do
        params = {
          article: {
            title: source_item.title + " updated title",
            description: source_item.description + " updated description",
            body: source_item.body + "updated body"
          }
        }

        put("/api/articles/non-existent-slug", params:, headers:, as: :json)
        expect(response).to have_http_status(:not_found)
      end
    end

    context '他ユーザーの記事を更新しようとする' do
      it '404エラーになる' do
        params = {
          article: {
            title: other_item.title + " updated title",
            description: other_item.description + " updated description",
            body: other_item.body + "updated body"
          }
        }

        put("/api/articles/#{other_item.slug}", params:, headers:, as: :json)
        expect(response).to have_http_status(:not_found)
      end
    end

    context '同じリクエストを２回送る' do
      it '1回目は更新され、２回目は更新されない' do
        params = {
          article: {
            title: source_item.title + " updated title",
            description: source_item.description + " updated description",
            body: source_item.body + "updated body"
          }
        }

        updated_at_1 = Article.find(source_item.id).updated_at
        put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        expect(response).to have_http_status(:ok)
        updated_at_2 = Article.find(source_item.id).updated_at
        expect(updated_at_2).to be > updated_at_1

        # 連続で更新
        put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
        expect(response).to have_http_status(:ok)
        updated_at_3 = Article.find(source_item.id).updated_at
        expect(updated_at_3).to eq updated_at_2 # リクエストがDBと同じ場合、更新処理がされない
      end
    end

    describe '入力チェックエラー' do
      context '更新対象項目を何も指定しない場合' do
        let!(:params) {
          { article: {
            # 空
          } }
        }

        it '入力チェックエラーになる' do
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
          expect(response).to have_http_status(:bad_request)
        end
      end

      # context '' do
      #   let!(:params) {
      #     { article: {
      #     } }
      #   }

      # end

      context '最低桁数未満の場合' do
        let!(:params) {
          { article: {
            title: "a" * 0,
            description: "a" * 0,
            body: "a" * 0
          } }
        }

        it '入力チェックエラーになる' do
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context '最低桁数の場合' do
        let!(:params) {
          { article: {
            title: "a" * 1,
            description: "a" * 1,
            body: "a" * 1
          } }
        }

        it '更新される' do
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
          expect(response).to have_http_status(:success)
        end
      end

      context '最大桁数の場合' do
        let!(:params) {
          { article: {
            title: "a" * 100,
            description: "a" * 500,
            body: "a" * 1000
          } }
        }

        it '更新される' do
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
          expect(response).to have_http_status(:success)
        end
      end

      context '最低桁数未満の場合' do
        let!(:params) {
          { article: {
            title: "a" * 101,
            description: "a" * 501,
            body: "a" * 1001
          } }
        }

        it '入力チェックエラーになる' do
          put("/api/articles/#{source_item.slug}", params:, headers:, as: :json)
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end
end
