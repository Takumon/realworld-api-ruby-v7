require 'rails_helper'

describe '/api/articles', type: :request do
  # ログインユーザー
  let(:user) {
    user = FactoryBot.create(:user)
    expect(user.valid?(context: :create)).to be_truthy
    user
  }

  let(:none_auth_headers) {
    {
      "CONTENT_TYPE": "application/json",
      "ACCEPT": "application/json"
    }
  }

  # 認証トークン
  let(:token) {
    params = { user: { email: user.email, password: user.password } }.to_json
    post('/api/users/login', params:, headers: none_auth_headers)

    expect(response).to have_http_status(:success)
    res =JSON.parse(response.body)['user']
    expect(res['token']).not_to be nil

    res['token']
  }

  let(:headers) {
    {
      "Authorization": "Token #{token}",
      **none_auth_headers
    }
  }

  describe "記事作成 POST /" do
    it '正常なリクエストの場合、ステータスコード 200 が返ること' do
      raw_params = {
        article: {
          slug: "slug",
          title: "title",
          description: "description",
          body: "body",
          tagList: [ "tag1", "tag2", "tag3", "tag4", "tag5" ]
        }
      }

      params = raw_params.to_json

      expect { post('/api/articles', params:, headers:) }.to change(Article, :count).by(1)
      expect(response).to have_http_status(:success)
      actual = JSON.parse(response.body)['article']
      input = raw_params[:article]
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

    describe "タグの登録について" do
      it 'タグが0文字の場合、400エラーになる' do
        # NG
        raw_params = {
          article: {
            slug: "slug",
            title: "title",
            description: "description",
            body: "body",
            tagList: [ "tag1", "tag2", "tag3", "tag4", "t" * 0 ]
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        raw_params = {
          article: {
            slug: "slug",
            title: "title",
            description: "description",
            body: "body",
            tagList: [ "tag1", "tag2", "tag3", "tag4", "t" * 1 ]
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:created)
      end

      it 'タグが21文字の場合、400エラーになる' do
        # N0
        raw_params = {
          article: {
            slug: "slug",
            title: "title",
            description: "description",
            body: "body",
            tagList: [ "tag1", "tag2", "tag3", "tag4", "t" * 21 ]
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        raw_params = {
          article: {
            slug: "slug",
            title: "title",
            description: "description",
            body: "body",
            tagList: [ "tag1", "tag2", "tag3", "tag4", "t" * 20 ]
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:created)
      end

      it 'タグが6件以上の場合、400エラーになる' do
        raw_params = {
          article: {
            slug: "slug",
            title: "title",
            description: "description",
            body: "body",
            tagList: [ "tag1", "tag2", "tag3", "tag4", "tag5", "tag6" ]
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)
      end

      it "タグ名が重複している場合、400エラーになる" do
        raw_params = {
          article: {
            slug: "slug",
            title: "title",
            description: "description",
            body: "body",
            tagList: [ "tag1", "tag2", "tag3", "tag4", "tag1" ]
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end


    describe '不正なリクエストパラメーターを指定すると400エラーになる' do
      it '必須チェック' do
        # NG
        headers = {
          "Authorization": "Token #{token}",
          "CONTENT_TYPE": "application/json",
          "ACCEPT": "application/json"
        }

        raw_params = {
          article: {}
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        raw_params = {
          article: {
            slug: "slug",
            title: "title",
            description: "description",
            body: "body"
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:success)
      end

      it '最小桁数チェック' do
        # NG
        headers = {
          "Authorization": "Token #{token}",
          "CONTENT_TYPE": "application/json",
          "ACCEPT": "application/json"
        }

        raw_params = {
          article: {
            slug: "a" * 0,
            title: "a" * 0,
            description: "a" * 0,
            body: "a" * 0
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        raw_params = {
          article: {
            slug: "a" * 1,
            title: "a" * 1,
            description: "a" * 1,
            body: "a" * 1
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:success)
      end

      it '最大桁数チェック' do
        # NG
        headers = {
          "Authorization": "Token #{token}",
          "CONTENT_TYPE": "application/json",
          "ACCEPT": "application/json"
        }

        raw_params = {
          article: {
            slug: "a" * 101,
            title: "a" * 101,
            description: "a" * 501,
            body: "a" * 1001
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)

        # OK
        raw_params = {
          article: {
            slug: "a" * 100,
            title: "a" * 100,
            description: "a" * 500,
            body: "a" * 1000
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'slugの一意性' do
      it '別ユーザーで同じslugの記事があっても正常に登録できる' do
        other = FactoryBot.create(:user, email: "other@sample.com")
        othersArticle = FactoryBot.create(:article, slug: "other-slug", user: other)

        headers = {
          "Authorization": "Token #{token}",
          "CONTENT_TYPE": "application/json",
          "ACCEPT": "application/json"
        }

        raw_params = {
          article: {
            slug: othersArticle.slug, # 他ユーザーの記事と同じslug
            title: "sample-title",
            description: "sample-description",
            body: "sample-body"
          }
        }

        params = raw_params.to_json

        expect { post('/api/articles', params:, headers:) }.to change(Article, :count).by(1)
        expect(response).to have_http_status(:success)
      end

      it '同じユーザーで同じslugの記事がある場合400エラーになる' do
        other = FactoryBot.create(:user, email: "other@sample.com")
        othersArticle = FactoryBot.create(:article, slug: "other-slug", user: other)
        myArticle = FactoryBot.create(:article, slug: othersArticle.slug, user: user)

        headers = {
          "Authorization": "Token #{token}",
          "CONTENT_TYPE": "application/json",
          "ACCEPT": "application/json"
        }

        raw_params = {
          article: {
            slug: myArticle.slug, # 自分の記事と同じslug
            title: "sample-title",
            description: "sample-description",
            body: "sample-body"
          }
        }

        params = raw_params.to_json

        post('/api/articles', params:, headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "記事更新 UPDATE /:id" do
    describe "タグの更新" do
      let(:tags) { FactoryBot.create_list(:tag, 10) }

      # 記事（タグなし）
      let(:source_item) {
        FactoryBot.create(
          :article, slug: 'source-item-slug',
          user: user,
        )
      }

      it "タグの追加ができる" do
        raw_params = {
          article: {
            tagList: [ tags[0].name ]
          }
        }

        params = raw_params.to_json

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:ok)

        actual = JSON.parse(response.body)['article']
        expect(actual['tagList'].size).to eq(1)
        expect(actual['tagList'][0]).to eq(tags[0].name)
      end

      it "タグの削除ができる" do
        # 追加
        raw_params = {
          article: {
            tagList: [ tags[0].name ]
          }
        }

        params = raw_params.to_json

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:ok)

        actual = JSON.parse(response.body)['article']
        expect(actual['tagList'].size).to eq(1)
        expect(actual['tagList'][0]).to eq(tags[0].name)

        # 削除
        raw_params = {
          article: {
            tagList: [] # 空配列
          }
        }

        params = raw_params.to_json

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:ok)

        actual = JSON.parse(response.body)['article']
        expect(actual['tagList'].size).to eq(0)
      end
    end

    describe "タグ以外の更新" do
      let(:tags) { FactoryBot.create_list(:tag, 10) }

      let(:source_item) {
        article = FactoryBot.create(
          :article, slug: 'source-item-slug',
          user: user,
        )

        # 紐づきのpositionはタグの並び順と一致するように登録
        tags[0..5].each_with_index do |tag, i|
          FactoryBot.create(:article_tag, article: article, tag: tag, position: i)
        end

        article.reload # 追加されたタグの紐づきを反映
      }

      # 他のユーザー
      let(:other_user) {
        other_user = FactoryBot.create(:user, email: 'other@sample.com')
        expect(other_user.valid?(context: :create)).to be_truthy
        other_user
      }

      let(:other_item) {
        article = FactoryBot.create(
          :article, slug: 'other-item-slug',
          user: other_user,
        )

        # 紐づきのpositionはタグの並び順と一致するように登録
        tags[6..9].each_with_index do |tag, i|
          FactoryBot.create(:article_tag, article: article, tag: tag, position: i)
        end

        article.reload # 追加されたタグの紐づきを反映
      }

      it '正常なリクエストの場合、ステータスコード 200 が返ること' do
        raw_params = {
          article: {
            title: source_item.title + " updated title",
            description: source_item.description + " updated description",
            body: source_item.body + "updated body"
          }
        }

        params = raw_params.to_json

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:ok)
        actual = JSON.parse(response.body)['article']
        input = raw_params[:article]
        expect(actual['title']).to eq(input[:title])
        expect(actual['description']).to eq(input[:description])
        expect(actual['body']).to eq(input[:body])
      end

      it "未認証の場合、401エラーになる" do
        raw_params = {
          article: {
            title: source_item.title + " updated title",
            description: source_item.description + " updated description",
            body: source_item.body + "updated body"
          }
        }

        params = raw_params.to_json

        put("/api/articles/#{source_item.slug}", params:) # トークンは未指定
        expect(response).to have_http_status(:unauthorized)
      end

      it '存在しない記事を更新しようとすると404エラーになる' do
        raw_params = {
          article: {
            title: source_item.title + " updated title",
            description: source_item.description + " updated description",
            body: source_item.body + "updated body"
          }
        }

        params = raw_params.to_json

        put("/api/articles/non-existent-slug", params:, headers:)
        expect(response).to have_http_status(:not_found)
      end

      it '他ユーザーの記事を更新しようとすると404エラーになる' do
        raw_params = {
          article: {
            title: other_item.title + " updated title",
            description: other_item.description + " updated description",
            body: other_item.body + "updated body"
          }
        }

        params = raw_params.to_json

        put("/api/articles/#{other_item.slug}", params:, headers:)
        expect(response).to have_http_status(:not_found)
      end

      it '楽観排他はなし（連続で更新できる）' do
        raw_params = {
          article: {
            title: source_item.title + " updated title",
            description: source_item.description + " updated description",
            body: source_item.body + "updated body"
          }
        }

        params = raw_params.to_json

        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:ok)

        # 連続で更新
        put("/api/articles/#{source_item.slug}", params:, headers:)
        expect(response).to have_http_status(:ok)
      end

      describe '不正なリクエストパラメーターを指定すると400エラーになる' do
        it '更新対象項目を何も指定しない場合、400エラーになる' do
          raw_params = {
            article: {
              # 空
            }
          }

        params = raw_params.to_json

          put("/api/articles/#{source_item.slug}", params:, headers:)
          expect(response).to have_http_status(:bad_request)
        end

        it '最低桁数チェック' do
          # NG
          raw_params = {
            article: {
              title: "a" * 0,
              description: "a" * 0,
              body: "a" * 0
            }
          }

        params = raw_params.to_json

          put("/api/articles/#{source_item.slug}", params:, headers:)
          expect(response).to have_http_status(:bad_request)

          # OK
          raw_params = {
            article: {
              title: "a" * 1,
              description: "a" * 1,
              body: "a" * 1
            }
          }

        params = raw_params.to_json

          put("/api/articles/#{source_item.slug}", params:, headers:)
          expect(response).to have_http_status(:success)
        end

        it '最大桁数チェック' do
          # NG
          raw_params = {
            article: {
              title: "a" * 101,
              description: "a" * 501,
              body: "a" * 1001
            }
          }

        params = raw_params.to_json

          put("/api/articles/#{source_item.slug}", params:, headers:)
          expect(response).to have_http_status(:bad_request)

          # OK
          raw_params = {
            article: {
              title: "a" * 100,
              description: "a" * 500,
              body: "a" * 1000
            }
          }

        params = raw_params.to_json

          put("/api/articles/#{source_item.slug}", params:, headers:)
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe "記事削除 DELETE /:id" do
    let(:source_item) { FactoryBot.create(:article, user:) }

    # 他のユーザー
    let(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let(:other_item) { FactoryBot.create(:article, slug: 'other-item-slug', user: other_user) }

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

  describe "記事取得 GET /:id" do
    let(:source_item) { FactoryBot.create(:article, slug: 'source-item-slug', user:) }

    # 他のユーザー
    let(:other_user) {
      other_user = FactoryBot.create(:user, email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    let(:other_item) { FactoryBot.create(:article, slug: 'other-item-slug', user: other_user) }


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
    # 他のユーザー
    let(:other_user) {
      other_user = FactoryBot.create(:user, username: 'other', email: 'other@sample.com')
      expect(other_user.valid?(context: :create)).to be_truthy
      other_user
    }

    describe do name = "クエリストリング未指定の場合"
      RSpec.shared_examples name do  |args|
        count = args[:count]
        expected_count = args[:expected_count]

        it "#{name}、全#{count}件の場合、#{expected_count}件取得できる" do
          FactoryBot.create_list(:article, count, user: user)

          get("/api/articles", headers:)
          expect(response).to have_http_status(:ok)

          res = JSON.parse(response.body)["articles"]
          expect(res.count).to eq(expected_count)
        end
      end

      include_examples name, count: 19, expected_count: 19
      include_examples name, count: 20, expected_count: 20
      include_examples name, count: 21, expected_count: 20
    end


    describe do name = "クエリストリングでlimitを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        limit = args[:limit]
        expected_count = args[:expected_count]

        it "全#{count}件の場合、limitを#limit}に指定すると、#{expected_count}件取得できる" do
          FactoryBot.create_list(:article, count, user: user)

          get("/api/articles?limit=#{limit}", headers:)
          expect(response).to have_http_status(:ok)

          res = JSON.parse(response.body)["articles"]
          expect(res.count).to eq(expected_count)
        end
      end

      include_examples name, count: 21, limit: 21, expected_count: 21
      include_examples name, count: 21, limit: 22, expected_count: 21
    end


    describe do name = "クエリストリングでoffsetを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        offset = args[:offset]
        expected_count = args[:expected_count]

        it "全#{count}件の場合、limitを#limit}に指定すると、#{expected_count}件取得できる" do
        FactoryBot.create_list(:article, count, user: user)

        get("/api/articles?offset=#{offset}", headers:)
          expect(response).to have_http_status(:ok)

          res = JSON.parse(response.body)["articles"]
          expect(res.count).to eq(expected_count)
        end
      end

      include_examples name, count: 22, offset: 1, expected_count: 20
      include_examples name, count: 22, offset: 2, expected_count: 20
      include_examples name, count: 22, offset: 3, expected_count: 19
    end

    describe do name = "クエリストリングでlimitとoffsetを指定する場合"
      RSpec.shared_examples name do |args|
        count = args[:count]
        limit = args[:limit]
        offset = args[:offset]
        expected_count = args[:expected_count]

        it "全#{count}件の場合、limitを#limit}に指定すると、#{expected_count}件取得できる" do
          FactoryBot.create_list(:article, count, user: user)

          get("/api/articles?limit=#{limit}&offset=#{offset}", headers:)
          expect(response).to have_http_status(:ok)

          res = JSON.parse(response.body)["articles"]
          expect(res.count).to eq(expected_count)
        end
      end

      include_examples name, count: 10, limit: 9, offset: 0, expected_count: 9
      include_examples name, count: 10, limit: 9, offset: 1, expected_count: 9
      include_examples name, count: 10, limit: 9, offset: 2, expected_count: 8
      include_examples name, count: 10, limit: 10, offset: 10, expected_count: 0
    end

    it "記事一覧が更新日時の降順である" do
      # バラバラに作成日時を設定
      item_2 = FactoryBot.create(:article, user: user, prefix: '2', updated_at: Time.current + 2.day, created_at: Time.current)
      item_1 = FactoryBot.create(:article, user: user, prefix: '1', updated_at: Time.current + 1.day, created_at: Time.current)
      item_3 = FactoryBot.create(:article, user: user, prefix: '3', updated_at: Time.current + 3.day, created_at: Time.current)

      get("/api/articles", headers:)
      expect(response).to have_http_status(:ok)

      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(3)
      expect(res[0]['title']).to eq(item_3.title)
      expect(res[1]['title']).to eq(item_2.title)
      expect(res[2]['title']).to eq(item_1.title)
    end

    it "投稿者でフィルターできる" do
      mine_1 = FactoryBot.create(:article, user: user, prefix: '1', updated_at: Time.current + 1.day, created_at: Time.current)
      other_2 = FactoryBot.create(:article, user: other_user, prefix: '2', updated_at: Time.current + 2.day, created_at: Time.current)
      mine_3 = FactoryBot.create(:article, user: user, prefix: '3', updated_at: Time.current + 3.day, created_at: Time.current)
      other_4 = FactoryBot.create(:article, user: other_user, prefix: '4', updated_at: Time.current + 4.day, created_at: Time.current)
      mine_5= FactoryBot.create(:article, user: user, prefix: '5', updated_at: Time.current + 5.day, created_at: Time.current)
      other_6 = FactoryBot.create(:article, user: other_user, prefix: '6', updated_at: Time.current + 6.day, created_at: Time.current)


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
      get("/api/articles?author=#{other_user.username}", headers:)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)["articles"]
      expect(res.count).to eq(3)
      expect(res[0]['title']).to eq(other_6.title)
      expect(res[1]['title']).to eq(other_4.title)
      expect(res[2]['title']).to eq(other_2.title)
    end
  end
end
