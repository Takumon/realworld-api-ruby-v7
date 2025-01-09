class Tag < ApplicationRecord
  has_many :articles, through: :article_tags

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }, uniqueness: { case_sensitive: false }
end
