require 'rails_helper'

describe 'GET/HEAD/OPTIONS /api/health', type: :request do
  let!(:headers) {
    {
      "CONTENT_TYPE": "application/json",
      "ACCEPT": "application/json"
    }
  }

  context "正常なリクエストの場合" do
    it "取得できる" do
      get('/api/health', headers:)
      expect(response).to have_http_status(:ok)
      res = JSON.parse(response.body)['data']
      expect(res['status']).to eq('ok')
    end
  end
end
