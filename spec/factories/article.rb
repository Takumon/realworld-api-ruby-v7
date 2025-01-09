FactoryBot.define do
  factory :article do
    transient do
      started_at { 0 }
      prefix { nil }
    end

    sequence(:slug) { |n| "sample-slug-#{started_at + n}" }
    sequence(:title) { |n| "サンプルタイトル-#{started_at + n}" }
    sequence(:description) { |n| "サンプル補足説明-#{started_at + n}" }
    sequence(:body) { |n| "サンプル本文だよ-#{started_at + n}" }


    after(:build) do |article, evaluator|
      if evaluator.prefix.present?
        prefix = evaluator.prefix
        article.slug = "#{prefix}-#{article.slug}"
        article.title = "#{prefix}-#{article.title}"
        article.description = "#{prefix}-#{article.description}"
        article.body = "#{prefix}-#{article.body}"
      end
    end
  end

  factory :tag do
    transient do
      started_at { 0 }
    end

    sequence(:name) { |n| "tagname-#{started_at + n}" }
  end

  factory :article_tag do
    association :article
    association :tag

    sequence(:position) { |n| n }
  end
end
