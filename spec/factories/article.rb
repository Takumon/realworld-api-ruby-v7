FactoryBot.define do
  factory :article do
    sequence(:slug) { |n| "sample-slug-#{n}" }
    sequence(:title) { |n| "サンプルタイトル-#{n}" }
    sequence(:description) { |n| "サンプル補足説明-#{n}" }
    sequence(:body) { |n| "サンプル本文だよ-#{n}" }

    transient do
      prefix { nil }
    end

    after(:build) do |article, evaluator|
      if evaluator.prefix.present?
        article.slug = "#{evaluator.prefix}-#{article.slug}"
        article.title = "#{evaluator.prefix}-#{article.title}"
        article.description = "#{evaluator.prefix}-#{article.description}"
        article.body = "#{evaluator.prefix}-#{article.body}"
      end
    end
  end
end
