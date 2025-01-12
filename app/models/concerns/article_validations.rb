module ArticleValidations
  extend ActiveSupport::Concern

  included do
    # 登録時のみのバリデーション
    with_options on: :create do
      validates :slug, presence: true, length: { minimum: 1, maximum: 100 }
      validates :title, presence: true
      validates :description, presence: true
      validates :body, presence: true
    end

    # 更新時は任意
    validates :title, length: { minimum: 1, maximum: 100 }, if: -> { title.nil? == false }
    validates :description, length: { minimum: 1, maximum: 500 }, if: -> { description.nil? == false }
    validates :body, length: { minimum: 1, maximum: 1000 }, if: -> { body.nil? == false }

    validate :validate_tag_list

    private

      def validate_tag_list
        list = self.tagList
        if list == nil || list.empty?
          return
        end

        if list.size > 5 # 0件でも可能
          errors.add(:tagList, "タグの指定は5つ以下にしてください")
        end

        if list.select { |one| one.length < 1 || one.length > 20 }.any?
          errors.add(:tagList, "タグは1文字以上20文字以下で指定してください")
        end

        if list.size != list.map(&:downcase).uniq.size
          errors.add(:tagList, "タグ名が重複しています")
        end
      end
  end

  class_methods do
    def add_uniqueness_validation
      validates :slug, uniqueness: { case_sensitive: false, scope: :user_id }, on: :create
    end
  end
end
