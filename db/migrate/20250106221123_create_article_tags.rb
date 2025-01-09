class CreateArticleTags < ActiveRecord::Migration[7.2]
  def change
    create_table :article_tags do |t|
      t.references :article, null: false, foreign_key: { on_delete: :cascade }, comment: "記事ID"
      t.references :tag, null: false, foreign_key: true, comment: "タグID"
      t.integer :position, null: false, comment: "並び順"

      t.timestamps
    end

    add_index :article_tags, [ :position, :article_id ], unique: true, name: "index_article_tags_on_position_and_article"
  end
end
