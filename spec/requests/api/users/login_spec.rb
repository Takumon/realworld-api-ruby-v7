require 'rails_helper'

describe 'POST /aip/users/login', type: :request do
  it 'ログインできる' do
    user = FactoryBot.create(:user)
    expect(user.valid?(context: :create)).to be_truthy

    params = { user: { email: user.email, password: user.password } }
    post('/api/users/login', params:)

    expect(response).to have_http_status(:success)
    res =JSON.parse(response.body)['data']['user']
    expect(res['token']).not_to be nil
    expect(res['bio']).to be nil
    expect(res['image']).to be nil

    expect(res['username']).to eq(user.username)
    expect(res['email']).to eq(user.email)
  end

  describe 'ログインできない' do
    it 'メールアドレスが正しいが、パスワードが間違っている' do
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy

      params = { user: { email: user.email, password: '間違っているパスワード' } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'メールアドレスが間違っている' do
      user = FactoryBot.create(:user)
      expect(user.valid?(context: :create)).to be_truthy

      params = { user: { email: 'wrong-address@sample.com', password: user.password } }
      post('/api/users/login', params:)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
