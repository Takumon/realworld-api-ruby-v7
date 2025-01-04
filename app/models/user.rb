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
    length: { minimum: 8, maximum: 72 }
end
