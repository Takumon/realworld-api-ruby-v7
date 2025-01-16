class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :article, null: false, foreign_key: { on_delete: :cascade }, comment: "コメント先の記事ID"
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, comment: "コメントしたユーザーのID"
      t.text :body, null: false, comment: "コメント本文"

      t.timestamps
    end

    # 複数コメント可能（ユニーク制約はなし）
  end
end
