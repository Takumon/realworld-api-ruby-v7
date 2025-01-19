class Comment < ApplicationRecord
  belongs_to :article
  belongs_to :user

  scope :sorted_by_created_at_desc, -> { order(created_at: :desc) }

  validates :body, presence: true, length: { minimum: 1, maximum: 200 }
  # 複数コメント可能（ユニーク制約はなし）

  def res(options = {}, current_user = nil)
    result = as_json(options.merge(only: [
      :id,
      :body
    ]))

    additional = {
      author: self.user.res({}, current_user)
    }

    if options[:root]
      result["comment"].merge!(additional)
    else
      result.merge!(additional)
    end

    result
  end
end
