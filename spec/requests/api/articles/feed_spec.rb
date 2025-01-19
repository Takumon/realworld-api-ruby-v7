require 'rails_helper'

describe 'GET /api/articles/feed', type: :request do
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
        FactoryBot.create_list(:article, count, user: other1)
        Relationship.create(follower: user, followed: other1)

          get("/api/articles/feed?offset=#{offset}", headers:)
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
        FactoryBot.create_list(:article, count, user: other1)
        Relationship.create(follower: user, followed: other1)

          get("/api/articles/feed?limit=#{limit}&offset=#{offset}", headers:)
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

    res = JSON.parse(response.body)['data']['articles']
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
