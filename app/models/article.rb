class Article < ApplicationRecord
  belongs_to :user

  validates :slug, presence: true, length: { minimum: 1, maximum: 100 }, uniqueness: { case_sensitive: false, scope: :user_id }
  validates :title, presence: true, length: { minimum: 1, maximum: 100 }
  validates :description, presence: true, length: { minimum: 1, maximum: 500 }
  validates :body, presence: true, length: { minimum: 1, maximum: 1000 }
end
