FactoryBot.define do
  factory :user do
    email { "test@sample.com" }
    username { "test-username" }
    password { "password" }
  end
end
