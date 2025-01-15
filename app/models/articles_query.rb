class ArticlesQuery
  include ActiveModel::Model
  include PaginationQuery

  attr_accessor :author, :tag, :favorited

  validates :tag, length: { minimum: 1, maximum: 100 }, if: -> { tag.nil? == false }

  validate :author_exists
  validate :tag_exists
  validate :favorited_exists

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

    def favorited_exists
      if favorited.nil?
        return
      end

      if User.exists?(username: favorited)
        return
      end

      errors.add(:favorited, "favoritedが見つかりません")
    end
end
