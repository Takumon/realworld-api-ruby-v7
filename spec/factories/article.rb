FactoryBot.define do
  factory :article do
    slug { "sample-slug" }
    title { "サンプルタイトル" }
    description { "サンプル補足説明" }
    body { "サンプル本文だよ" }
  end
end
