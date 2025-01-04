class CreateArticles < ActiveRecord::Migration[7.2]
  def change
    create_table :articles do |t|
      t.string :slug, null: false, comment: "URLの一部"
      t.string :title, null: false, comment: "タイトル"
      t.text :description, null: false, comment: "記事の説明"
      t.text :body, null: false, comment: "記事の本文"

      t.references :user
      t.timestamps
    end

    add_index :articles, [ :slug, :user_id ], unique: true, name: "index_articles_on_slug_and_user"
  end
end
