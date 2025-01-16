class Article < ApplicationRecord
  include ArticleValidations
  add_uniqueness_validation

  belongs_to :user

  has_many :article_tags, -> { order(:position) }, dependent: :destroy
  has_many :tags, through: :article_tags

  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  has_many :comments, dependent: :destroy

  scope :sorted_by_updated_at_desc, -> { order(updated_at: :desc) }

  attr_accessor :tagList

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
end
