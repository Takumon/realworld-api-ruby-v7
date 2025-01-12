class ArticleUpdateRequest
  include ActiveModel::Model
  include ArticleValidations

  attr_accessor :title, :description, :body, :tagList

  def bind_to(article)
    self.transfer(:title, article)
    self.transfer(:body, article)
    self.transfer(:description, article)

    if tagList.nil?
      article.tagList = article.tags.map(&:name)
    else
      article.tagList = tagList
    end
  end

  private
    def transfer(attr_name, obj)
      val = self.send(attr_name)
      return if val.nil?

      obj.send("#{attr_name}=", val)
    end
end
