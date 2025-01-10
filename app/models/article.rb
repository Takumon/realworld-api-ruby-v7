class Article < ApplicationRecord
  belongs_to :user
  has_many :article_tags, -> { order(:position) }, dependent: :destroy
  has_many :tags, through: :article_tags

  # 登録時のみのバリデーション
  with_options on: :create do
    validates :slug,
      presence: true,
      length: { minimum: 1, maximum: 100 },
      uniqueness: { case_sensitive: false, scope: :user_id }
    validates :title, presence: true
    validates :description, presence: true
    validates :body, presence: true
  end

  validates :title, length: { minimum: 1, maximum: 100 }
  validates :description, length: { minimum: 1, maximum: 500 }
  validates :body, length: { minimum: 1, maximum: 1000 }

  attr_accessor :tagList
  validate :validate_tag_list

  scope :sorted_by_updated_at_desc, -> { order(updated_at: :desc) }

  def save_with_relations
    ActiveRecord::Base.transaction do
      self.save!


      req_tags = self.tagList
      req_has_data = req_tags.nil? == false && req_tags.any?

      db_tags = self.tags.to_a
      db_has_data = db_tags.any?

      # リクエストにないがDBにある → 削除
      if db_has_data
        db_tags.each do |db_tag|
          if req_has_data == false || req_tags.include?(db_tag.name) === false
            self.article_tags.find_by(tag_id: db_tag.id).destroy
          end
        end
      end

      # リクエストにあって、
      if req_has_data
        req_tags.each_with_index  do |name, i|
          lower_name = name.downcase

          tag_record = Tag.find_by(name: lower_name)

          if tag_record.nil? # タグ自体がDBにもない場合
            new_tag = Tag.create(name: lower_name)
            self.article_tags.create(tag: new_tag, position: i) # 紐づけも登録
          else # タグ自体はDBにある場合
            # DBにない → 登録
            association = self.article_tags.find_by(tag_id: tag_record.id)
            if association.nil?
              self.article_tags.create(tag: tag_record, position: i) # 紐づけも登録
            else
              # DBにある → 登録・位置の更新
              association.update(position: i)
            end
          end
        end
      end

      self.tags.reload # tags を更新
    end
  end

  private
    def validate_tag_list
      list = self.tagList

      return if list.blank?

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
