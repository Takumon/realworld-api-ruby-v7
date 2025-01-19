require 'rails_helper'

describe 'GET /api/articles', type: :request do
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

    context '存在しないfavorited' do
      it '入力チェックエラーになる' do
        user_name = 'fictional_user'
        get("/api/articles?favorited=#{user_name}", headers:)
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

          res = JSON.parse(response.body)['data']['articles']
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

          res = JSON.parse(response.body)['data']['articles']
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

          res = JSON.parse(response.body)['data']['articles']
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

          res = JSON.parse(response.body)['data']['articles']
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

    res = JSON.parse(response.body)['data']['articles']
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
    res = JSON.parse(response.body)['data']['articles']
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
    res = JSON.parse(response.body)['data']['articles']
    expect(res.count).to eq(3)
    expect(res[0]['title']).to eq(mine_5.title)
    expect(res[1]['title']).to eq(mine_3.title)
    expect(res[2]['title']).to eq(mine_1.title)

    # フィルターあり(other)
    get("/api/articles?author=#{other1.username}", headers:)
    expect(response).to have_http_status(:ok)
    res = JSON.parse(response.body)['data']['articles']
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
    res = JSON.parse(response.body)['data']['articles']
    expect(res.count).to eq(4)
    expect(res[0]['title']).to eq(other_4.title)
    expect(res[1]['title']).to eq(mine_3.title)
    expect(res[2]['title']).to eq(other_2.title)
    expect(res[3]['title']).to eq(mine_1.title)

    # フィルターあり
    get("/api/articles?tag=#{tags[0].name}", headers:)
    expect(response).to have_http_status(:ok)
    res = JSON.parse(response.body)['data']['articles']
    expect(res.count).to eq(2)
    expect(res[0]['title']).to eq(other_2.title)
    expect(res[1]['title']).to eq(mine_1.title)

    # フィルターあり
    get("/api/articles?tag=#{tags[2].name}", headers:)
    expect(response).to have_http_status(:ok)
    res = JSON.parse(response.body)['data']['articles']
    expect(res.count).to eq(2)
    expect(res[0]['title']).to eq(other_4.title)
    expect(res[1]['title']).to eq(mine_3.title)
  end


  it "お気に入りでフィルターできる" do
    now = Time.current

    mine_1 = FactoryBot.create(:article, user: user, prefix: '1', updated_at: now + 1.day, created_at: now)
    FactoryBot.create(:favorite, article: mine_1, user: user)
    FactoryBot.create(:favorite, article: mine_1, user: other1)

    other_2 = FactoryBot.create(:article, user: other1, prefix: '2', updated_at: now + 2.day, created_at: now)
    FactoryBot.create(:favorite, article: other_2, user: user)
    FactoryBot.create(:favorite, article: other_2, user: other1)

    mine_3 = FactoryBot.create(:article, user: user, prefix: '3', updated_at: now + 3.day, created_at: now)
    FactoryBot.create(:favorite, article: mine_3, user: other1)
    FactoryBot.create(:favorite, article: mine_3, user: other2)

    other_4 = FactoryBot.create(:article, user: other1, prefix: '4', updated_at: now + 4.day, created_at: now)
    FactoryBot.create(:favorite, article: other_4, user: other1)
    FactoryBot.create(:favorite, article: other_4, user: other2)

    # フィルターなし
    get("/api/articles", headers:)
    expect(response).to have_http_status(:ok)
    res = JSON.parse(response.body)['data']['articles']
    expect(res.count).to eq(4)
    expect(res[0]['title']).to eq(other_4.title)
    expect(res[1]['title']).to eq(mine_3.title)
    expect(res[2]['title']).to eq(other_2.title)
    expect(res[3]['title']).to eq(mine_1.title)

    # フィルターあり
    get("/api/articles?favorited=#{user.username}", headers:)
    expect(response).to have_http_status(:ok)
    res = JSON.parse(response.body)['data']['articles']
    expect(res.count).to eq(2)
    expect(res[0]['title']).to eq(other_2.title)
    expect(res[1]['title']).to eq(mine_1.title)

    # フィルターあり
    get("/api/articles?favorited=#{other2.username}", headers:)
    expect(response).to have_http_status(:ok)
    res = JSON.parse(response.body)['data']['articles']
    expect(res.count).to eq(2)
    expect(res[0]['title']).to eq(other_4.title)
    expect(res[1]['title']).to eq(mine_3.title)
  end
end
