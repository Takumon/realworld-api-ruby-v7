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
        p = evaluator.prefix
        article.slug = "#{p}-#{article.slug}"
        article.title = "#{p}-#{article.title}"
        article.description = "#{p}-#{article.description}"
        article.body = "#{p}-#{article.body}"
      end
    end
  end

  factory :tag do
    transient do
      started_at { 0 }
      prefix { nil }
    end

    sequence(:name) { |n| "tagname-#{started_at + n}" }

    after(:build) do |tag, evaluator|
      if evaluator.prefix.present?
        p = evaluator.prefix
        tag.name = "#{p}-#{tag.name}"
      end
    end
  end

  factory :article_tag do
    association :article
    association :tag

    sequence(:position) { |n| n }
  end

  factory :favorite do
    association :user
    association :article
  end

  factory :comment do
    association :article
    association :user

    transient do
      started_at { 0 }
      prefix { nil }
    end

    sequence(:body) { |n| "コメント本文-#{started_at + n}" }

    after(:build) do |comment, evaluator|
      if evaluator.prefix.present?
        p = evaluator.prefix
        comment.body = "#{p}-#{comment.body}"
      end
    end
  end
end
