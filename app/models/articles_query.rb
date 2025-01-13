class ArticlesQuery
  include ActiveModel::Model
  include PaginationQuery

  attr_accessor :author, :tag

  validates :tag, length: { minimum: 1, maximum: 100 }, if: -> { tag.nil? == false }

  validate :author_exists
  validate :tag_exists

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
