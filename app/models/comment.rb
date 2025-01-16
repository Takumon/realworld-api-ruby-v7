class Comment < ApplicationRecord
  belongs_to :article
  belongs_to :user

  scope :sorted_by_created_at_desc, -> { order(created_at: :desc) }

  validates :body, presence: true, length: { minimum: 1, maximum: 200 }
  # 複数コメント可能（ユニーク制約はなし）
end
