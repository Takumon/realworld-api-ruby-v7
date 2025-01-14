class CreateFavorites < ActiveRecord::Migration[7.2]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, comment: "ユーザーID"
      t.references :article, null: false, foreign_key: { on_delete: :cascade }, comment: "記事ID"
      t.timestamps
    end

    add_index :favorites, [ :user_id, :article_id ], unique: true, name: "index_favorites_on_user_id_and_article_id"
  end
end
