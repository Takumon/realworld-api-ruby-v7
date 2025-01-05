class Article < ApplicationRecord
  belongs_to :user

  # 登録時のみのバリデーション
  with_options on: :create do
    validates :slug,
      presence: true,
      length: { minimum: 1, maximum: 100 },
      uniqueness: { case_sensitive: false, scope: :user_id }
    validates :title, presence: true
    validates :description, presence: true
    validates :body, presence: true
  end

  validates :title, length: { minimum: 1, maximum: 100 }
  validates :description, length: { minimum: 1, maximum: 500 }
  validates :body, length: { minimum: 1, maximum: 1000 }
end
