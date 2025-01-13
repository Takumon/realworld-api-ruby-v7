FactoryBot.define do
  factory :user do
    transient do
      prefix { nil }
    end

    email { "test@sample.com" }
    username { "test-username" }
    password { "password" }

    after(:build) do |user, evaluator|
      if evaluator.prefix.present?
        p = evaluator.prefix
        user.email = "#{p}-#{user.email}"
        user.username = "#{p}-#{user.username}"
        user.password = "#{p}-#{user.password}"
      end
    end
  end
end
