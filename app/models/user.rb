class User < ApplicationRecord
  has_secure_password
  has_many :articles

  has_many :active_relationships,
            class_name: "Relationship",
            foreign_key: :follower_id,
            dependent: :destroy

  has_many :passive_relationships,
            class_name: "Relationship",
            foreign_key: :followed_id,
            dependent: :destroy

  has_many :following, through: :active_relationships, source: :followed

  has_many :followers, through: :passive_relationships, source: :follower

  has_many :favorites, dependent: :destroy
  has_many :favorited_articles, through: :favorites, source: :article

  validates :username,
    presence: true,
    length: { minimum: 2, maximum: 100 }

  validates :email,
    presence: true,
    length: { minimum: 4, maximum: 255 },
    uniqueness: { case_sensitive: false }

  validates :password,
    presence: true,
    length: { minimum: 8, maximum: 72 },
    on: :create

  validates :bio,
    length: { minimum: 1, maximum: 500 },
    on: :update

  validates :image,
    length: { minimum: 1, maximum: 500 },
    on: :update

  validates :lock_version,
    presence: true,
    on: :update
end
