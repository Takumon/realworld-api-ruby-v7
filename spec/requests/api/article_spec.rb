require 'rails_helper'

describe '/api/articles', type: :request do
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



  describe "登録 POST /" do
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
        expect { post('/api/articles', params:, headers:, as: :json) }.to change(Article, :count).by(1)
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
        expect(actual['author']['email']).to be nil
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



  describe "更新 UPDATE /:id" do
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



  describe "削除 DELETE /:id" do
    let!(:source_item) { FactoryBot.create(:article, user:) }

    # 他のユーザー
    let!(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let!(:other_item) { FactoryBot.create(:article, slug: 'other-item-slug', user: other_user) }

    context '正常なリクエストの場合' do
      it '削除される' do
        expect {
          delete("/api/articles/#{source_item.slug}", headers:)
        }.to change(Article, :count).by(-1)
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



  describe "詳細 GET /:id" do
    let!(:source_item) { FactoryBot.create(:article, slug: 'source-item-slug', user:) }

    # 他のユーザー
    let!(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let!(:other_item) { FactoryBot.create(:article, slug: 'other-item-slug', user: other_user) }


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
        expect(actual['author']['email']).to be nil # emailは含まれない
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

    context '他ユーザーの記事を更新しようとする' do
      it '404エラーになる' do
        get("/api/articles/#{other_item.slug}", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end
  end



  describe "一覧 GET /" do
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


    # 他のユーザー3
    let!(:other3) {
      other_user = FactoryBot.create(:user, prefix: 'other3')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    describe '入力チェク系' do
      let!(:articles) { FactoryBot.create_list(:article, 10, user: user) }
      let!(:tags) { FactoryBot.create_list(:tag, 5) }

      context 'offsetが数値以外' do
        it '入力チェックエラーになる' do
          offset = "hoge"
          get("/api/articles?offset=#{offset}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'offsetが最低値未満' do
        it '入力チェックエラーになる' do
          offset = -1
          get("/api/articles?offset=#{offset}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'offsetが最低値' do
        it '一覧が取得できる' do
          offset = 0
          get("/api/articles?offset=#{offset}", headers:)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'offsetが最大値' do
        it '一覧が取得できる' do
          offset = 1000
          get("/api/articles?offset=#{offset}", headers:)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'offsetが最大値より大きい' do
        it '入力チェックエラーになる' do
          offset = 1001
          get("/api/articles?offset=#{offset}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'limitが数値以外' do
        it '入力チェックエラーになる' do
          limit = "hoge"
          get("/api/articles?limit=#{limit}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'limitが最低値未満' do
        it '入力チェックエラーになる' do
          limit = -1
          get("/api/articles?limit=#{limit}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'limitが最低値' do
        it '一覧が取得できる' do
          limit = 0
          get("/api/articles?limit=#{limit}", headers:)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'limitが最大値' do
        it '一覧が取得できる' do
          limit = 100
          get("/api/articles?limit=#{limit}", headers:)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'limitが最大値より大きい' do
        it '入力チェックエラーになる' do
          limit = 101
          get("/api/articles?limit=#{limit}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'authorが存在しないユーザー' do
        it 'invalid_user_name' do
          author = "invalid_user_name"
          get("/api/articles?author=#{author}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'tagが最低桁数未満' do
        it '入力チェックエラーになる' do
          tag_name = 'a' * 0
          get("/api/articles?tag=#{tag_name}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'tagが最低桁数' do
        it '一覧が取得できる' do
          tag_name = 'a' * 1
          FactoryBot.create(:tag, name: tag_name)
          get("/api/articles?tag=#{tag_name}", headers:)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'tagが最大桁数' do
        it '一覧が取得できる' do
          tag_name = 'a' * 100
          FactoryBot.create(:tag, name: tag_name)
          get("/api/articles?tag=#{tag_name}", headers:)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'tagが最大桁数より大きい' do
        it '入力チェックエラーになる' do
          tag_name = 'a' * 101
          get("/api/articles?tag=#{tag_name}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context '存在しないtag' do
        it '入力チェックエラーになる' do
          tag_name = 'invalid_tag'
          get("/api/articles?tag=#{tag_name}", headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context do name = "検索条件未指定の場合"
      RSpec.shared_examples name do  |args|
        count = args[:count]
        expected_count = args[:expected_count]

        context "#{name}、全#{count}件の場合" do
          it "#{expected_count}件取得できる" do
            FactoryBot.create_list(:article, count, user: user)

            get("/api/articles", headers:)
            expect(response).to have_http_status(:ok)

            res = JSON.parse(response.body)["articles"]
            expect(res.count).to eq(expected_count)
          end
        end
      end

      include_examples name, count: 19, expected_count: 19
      include_examples name, count: 20, expected_count: 20
      include_examples name, count: 21, expected_count: 20
    end


    context do name = "検索条件でlimitを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        limit = args[:limit]
        expected_count = args[:expected_count]

        context "全#{count}件の場合、limitを#limit}に指定する" do
          it "#{expected_count}件取得できる" do
            FactoryBot.create_list(:article, count, user: user)

            get("/api/articles?limit=#{limit}", headers:)
            expect(response).to have_http_status(:ok)

            res = JSON.parse(response.body)["articles"]
            expect(res.count).to eq(expected_count)
          end
        end
      end

      include_examples name, count: 21, limit: 21, expected_count: 21
      include_examples name, count: 21, limit: 22, expected_count: 21
    end


    context do name = "検索条件でoffsetを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        offset = args[:offset]
        expected_count = args[:expected_count]

        context "全#{count}件の場合、limitを#limit}に指定する" do
          it "#{expected_count}件取得できる" do
            FactoryBot.create_list(:article, count, user: user)

            get("/api/articles?offset=#{offset}", headers:)
            expect(response).to have_http_status(:ok)

            res = JSON.parse(response.body)["articles"]
            expect(res.count).to eq(expected_count)
          end
        end
      end

      include_examples name, count: 22, offset: 1, expected_count: 20
      include_examples name, count: 22, offset: 2, expected_count: 20
      include_examples name, count: 22, offset: 3, expected_count: 19
    end

    context do name = "検索条件でlimitとoffsetを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        limit = args[:limit]
        offset = args[:offset]
        expected_count = args[:expected_count]

        context "全#{count}件の場合、limitを#limit}に指定する" do
          it "#{expected_count}件取得できる" do
            FactoryBot.create_list(:article, count, user: user)

            get("/api/articles?limit=#{limit}&offset=#{offset}", headers:)
            expect(response).to have_http_status(:ok)

            res = JSON.parse(response.body)["articles"]
            expect(res.count).to eq(expected_count)
          end
        end
      end

      include_examples name, count: 10, limit: 9, offset: 0, expected_count: 9
      include_examples name, count: 10, limit: 9, offset: 1, expected_count: 9
      include_examples name, count: 10, limit: 9, offset: 2, expected_count: 8
      include_examples name, count: 10, limit: 10, offset: 10, expected_count: 0
    end

    it "記事一覧が更新日時の降順である" do
      Relationship.create(follower: user, followed: other1)
      # バラバラに作成日時を設定
      now = Time.current
      item_4 = FactoryBot.create(:article, user: other1, prefix: '4', updated_at: now + 4.day, created_at: now)
      item_1 = FactoryBot.create(:article, user: other1, prefix: '1', updated_at: now + 1.day, created_at: now)
      item_7 = FactoryBot.create(:article, user: other1, prefix: '7', updated_at: now + 7.day, created_at: now)

      Relationship.create(follower: user, followed: other2)
      item_5 = FactoryBot.create(:article, user: other2, prefix: '5', updated_at: now + 5.day, created_at: now)
      item_2 = FactoryBot.create(:article, user: other2, prefix: '2', updated_at: now + 2.day, created_at: now)
      item_8 = FactoryBot.create(:article, user: other2, prefix: '8', updated_at: now + 8.day, created_at: now)

      # other3はフォローしない
      item_6 = FactoryBot.create(:article, user: other3, prefix: '6', updated_at: now + 6.day, created_at: now)
      item_3 = FactoryBot.create(:article, user: other3, prefix: '3', updated_at: now + 3.day, created_at: now)
      item_9 = FactoryBot.create(:article, user: other3, prefix: '9', updated_at: now + 9.day, created_at: now)

      get("/api/articles", headers:)
      expect(response).to have_http_status(:ok)

      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(9)
      expect(res[0]['title']).to eq(item_9.title)
      expect(res[0]['author']['following']).to eq(false)

      expect(res[1]['title']).to eq(item_8.title)
      expect(res[1]['author']['following']).to eq(true)

      expect(res[2]['title']).to eq(item_7.title)
      expect(res[2]['author']['following']).to eq(true)

      expect(res[3]['title']).to eq(item_6.title)
      expect(res[3]['author']['following']).to eq(false)

      expect(res[4]['title']).to eq(item_5.title)
      expect(res[4]['author']['following']).to eq(true)

      expect(res[5]['title']).to eq(item_4.title)
      expect(res[5]['author']['following']).to eq(true)

      expect(res[6]['title']).to eq(item_3.title)
      expect(res[6]['author']['following']).to eq(false)

      expect(res[7]['title']).to eq(item_2.title)
      expect(res[7]['author']['following']).to eq(true)

      expect(res[8]['title']).to eq(item_1.title)
      expect(res[8]['author']['following']).to eq(true)
    end


    it "投稿者でフィルターできる" do
      mine_1 = FactoryBot.create(:article, user: user, prefix: '1', updated_at: Time.current + 1.day, created_at: Time.current)
      other_2 = FactoryBot.create(:article, user: other1, prefix: '2', updated_at: Time.current + 2.day, created_at: Time.current)
      mine_3 = FactoryBot.create(:article, user: user, prefix: '3', updated_at: Time.current + 3.day, created_at: Time.current)
      other_4 = FactoryBot.create(:article, user: other1, prefix: '4', updated_at: Time.current + 4.day, created_at: Time.current)
      mine_5= FactoryBot.create(:article, user: user, prefix: '5', updated_at: Time.current + 5.day, created_at: Time.current)
      other_6 = FactoryBot.create(:article, user: other1, prefix: '6', updated_at: Time.current + 6.day, created_at: Time.current)


      # フィルターなし
      get("/api/articles", headers:)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(6)
      expect(res[0]['title']).to eq(other_6.title)
      expect(res[1]['title']).to eq(mine_5.title)
      expect(res[2]['title']).to eq(other_4.title)
      expect(res[3]['title']).to eq(mine_3.title)
      expect(res[4]['title']).to eq(other_2.title)
      expect(res[5]['title']).to eq(mine_1.title)

      # フィルターあり(mine)
      get("/api/articles?author=#{user.username}", headers:)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(3)
      expect(res[0]['title']).to eq(mine_5.title)
      expect(res[1]['title']).to eq(mine_3.title)
      expect(res[2]['title']).to eq(mine_1.title)

      # フィルターあり(other)
      get("/api/articles?author=#{other1.username}", headers:)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(3)
      expect(res[0]['title']).to eq(other_6.title)
      expect(res[1]['title']).to eq(other_4.title)
      expect(res[2]['title']).to eq(other_2.title)
    end

    it "タグでフィルターできる" do
      tags = FactoryBot.create_list(:tag, 5)

      now = Time.current

      mine_1 = FactoryBot.create(:article, user: user, prefix: '1', updated_at: now + 1.day, created_at: now)
      FactoryBot.create(:article_tag, article: mine_1, tag: tags[0], position: 0)
      FactoryBot.create(:article_tag, article: mine_1, tag: tags[1], position: 1)

      other_2 = FactoryBot.create(:article, user: other1, prefix: '2', updated_at: now + 2.day, created_at: now)
      FactoryBot.create(:article_tag, article: other_2, tag: tags[0], position: 0)
      FactoryBot.create(:article_tag, article: other_2, tag: tags[1], position: 1)

      mine_3 = FactoryBot.create(:article, user: user, prefix: '3', updated_at: now + 3.day, created_at: now)
      FactoryBot.create(:article_tag, article: mine_3, tag: tags[1], position: 0)
      FactoryBot.create(:article_tag, article: mine_3, tag: tags[2], position: 1)

      other_4 = FactoryBot.create(:article, user: other1, prefix: '4', updated_at: now + 4.day, created_at: now)
      FactoryBot.create(:article_tag, article: other_4, tag: tags[1], position: 0)
      FactoryBot.create(:article_tag, article: other_4, tag: tags[2], position: 1)

      # フィルターなし
      get("/api/articles", headers:)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(4)
      expect(res[0]['title']).to eq(other_4.title)
      expect(res[1]['title']).to eq(mine_3.title)
      expect(res[2]['title']).to eq(other_2.title)
      expect(res[3]['title']).to eq(mine_1.title)

      # フィルターあり
      get("/api/articles?tag=#{tags[0].name}", headers:)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(2)
      expect(res[0]['title']).to eq(other_2.title)
      expect(res[1]['title']).to eq(mine_1.title)

      # フィルターあり
      get("/api/articles?tag=#{tags[2].name}", headers:)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(2)
      expect(res[0]['title']).to eq(other_4.title)
      expect(res[1]['title']).to eq(mine_3.title)
    end
  end

  describe "フィード一覧 GET /feed" do
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


    # 他のユーザー3
    let!(:other3) {
      other_user = FactoryBot.create(:user, prefix: 'other3')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    context 'offsetが数値以外' do
      it '入力チェックエラーになる' do
        offset = "hoge"
        get("/api/articles/feed?offset=#{offset}", headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'offsetが最低値未満' do
      it '入力チェックエラーになる' do
        offset = -1
        get("/api/articles/feed?offset=#{offset}", headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'offsetが最低値' do
      it '一覧が取得できる' do
        offset = 0
        get("/api/articles/feed?offset=#{offset}", headers:)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'offsetが最大値' do
      it '一覧が取得できる' do
        offset = 1000
        get("/api/articles/feed?offset=#{offset}", headers:)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'offsetが最大値より大きい' do
      it '入力チェックエラーになる' do
        offset = 1001
        get("/api/articles/feed?offset=#{offset}", headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'limitが数値以外' do
      it '入力チェックエラーになる' do
        limit = "hoge"
        get("/api/articles/feed?limit=#{limit}", headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'limitが最低値未満' do
      it '入力チェックエラーになる' do
        limit = -1
        get("/api/articles/feed?limit=#{limit}", headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'limitが最低値' do
      it '一覧が取得できる' do
        limit = 0
        get("/api/articles/feed?limit=#{limit}", headers:)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'limitが最大値' do
      it '一覧が取得できる' do
        limit = 100
        get("/api/articles/feed?limit=#{limit}", headers:)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'limitが最大値より大きい' do
      it '入力チェックエラーになる' do
        limit = 101
        get("/api/articles/feed?limit=#{limit}", headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context do name = "検索条件でlimitを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        limit = args[:limit]
        expected_count = args[:expected_count]

        context "全#{count}件の場合、limitを#limit}に指定する" do
          it "#{expected_count}件取得できる" do
            FactoryBot.create_list(:article, count, user: other1)
            Relationship.create(follower: user, followed: other1)

            get("/api/articles/feed?limit=#{limit}", headers:)
            expect(response).to have_http_status(:ok)

            res = JSON.parse(response.body)["articles"]
            expect(res.count).to eq(expected_count)
          end
        end
      end

      include_examples name, count: 21, limit: 21, expected_count: 21
      include_examples name, count: 21, limit: 22, expected_count: 21
    end


    context do name = "検索条件でoffsetを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        offset = args[:offset]
        expected_count = args[:expected_count]

        context "全#{count}件の場合、limitを#limit}に指定する" do
          it "#{expected_count}件取得できる" do
          FactoryBot.create_list(:article, count, user: other1)
          Relationship.create(follower: user, followed: other1)

            get("/api/articles/feed?offset=#{offset}", headers:)
            expect(response).to have_http_status(:ok)

            res = JSON.parse(response.body)["articles"]
            expect(res.count).to eq(expected_count)
          end
        end
      end

      include_examples name, count: 22, offset: 1, expected_count: 20
      include_examples name, count: 22, offset: 2, expected_count: 20
      include_examples name, count: 22, offset: 3, expected_count: 19
    end

    context do name = "検索条件でlimitとoffsetを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        limit = args[:limit]
        offset = args[:offset]
        expected_count = args[:expected_count]

        context "全#{count}件の場合、limitを#limit}に指定する" do
          it "#{expected_count}件取得できる" do
          FactoryBot.create_list(:article, count, user: other1)
          Relationship.create(follower: user, followed: other1)

            get("/api/articles/feed?limit=#{limit}&offset=#{offset}", headers:)
            expect(response).to have_http_status(:ok)

            res = JSON.parse(response.body)["articles"]
            expect(res.count).to eq(expected_count)
          end
        end
      end

      include_examples name, count: 10, limit: 9, offset: 0, expected_count: 9
      include_examples name, count: 10, limit: 9, offset: 1, expected_count: 9
      include_examples name, count: 10, limit: 9, offset: 2, expected_count: 8
      include_examples name, count: 10, limit: 10, offset: 10, expected_count: 0
    end

    it "一覧が更新日時の降順である" do
      Relationship.create(follower: user, followed: other1)
      # バラバラに作成日時を設定
      now = Time.current
      item_4 = FactoryBot.create(:article, user: other1, prefix: '4', updated_at: now + 4.day, created_at: now)
      item_1 = FactoryBot.create(:article, user: other1, prefix: '1', updated_at: now + 1.day, created_at: now)
      item_7 = FactoryBot.create(:article, user: other1, prefix: '7', updated_at: now + 7.day, created_at: now)

      Relationship.create(follower: user, followed: other2)
      item_5 = FactoryBot.create(:article, user: other2, prefix: '5', updated_at: now + 5.day, created_at: now)
      item_2 = FactoryBot.create(:article, user: other2, prefix: '2', updated_at: now + 2.day, created_at: now)
      item_8 = FactoryBot.create(:article, user: other2, prefix: '8', updated_at: now + 8.day, created_at: now)

      # other3はフォローしない
      item_6 = FactoryBot.create(:article, user: other3, prefix: '6', updated_at: now + 6.day, created_at: now)
      item_3 = FactoryBot.create(:article, user: other3, prefix: '3', updated_at: now + 3.day, created_at: now)
      item_9 = FactoryBot.create(:article, user: other3, prefix: '9', updated_at: now + 9.day, created_at: now)

      get("/api/articles/feed", headers:)
      expect(response).to have_http_status(:ok)

      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(6)
      expect(res[0]['title']).to eq(item_8.title)
      expect(res[0]['author']['following']).to eq(true)

      expect(res[1]['title']).to eq(item_7.title)
      expect(res[1]['author']['following']).to eq(true)

      expect(res[2]['title']).to eq(item_5.title)
      expect(res[2]['author']['following']).to eq(true)

      expect(res[3]['title']).to eq(item_4.title)
      expect(res[3]['author']['following']).to eq(true)

      expect(res[4]['title']).to eq(item_2.title)
      expect(res[4]['author']['following']).to eq(true)

      expect(res[5]['title']).to eq(item_1.title)
      expect(res[5]['author']['following']).to eq(true)
    end
  end
end
