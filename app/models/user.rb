class User < ApplicationRecord
  has_secure_password

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
