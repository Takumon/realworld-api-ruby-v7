class ArticlesQuery
  include ActiveModel::Model
  OFFSET_DEFAULT = 0
  LIMIT_DEFAULT = 20

  attr_accessor :offset, :limit, :author, :tag

  validates :offset,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1000
    },
    allow_nil: true
  validates :limit,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    },
    allow_nil: true

  validates :tag, length: { minimum: 1, maximum: 100 }, if: -> { tag.nil? == false }

  validate :author_exists
  validate :tag_exists

  def offset
    @offset || OFFSET_DEFAULT
  end

  def limit
    @limit || LIMIT_DEFAULT
  end

  private
    def author_exists
      if author.nil?
        return
      end

      if User.exists?(username: author)
        return
      end

      errors.add(:author, "authorが見つかりません")
    end

    def tag_exists
      if tag.nil?
        return
      end

      if Tag.exists?(name: tag)
        return
      end

      errors.add(:tag, "tagが見つかりません")
    end
end
