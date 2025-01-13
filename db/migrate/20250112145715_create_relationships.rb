class CreateRelationships < ActiveRecord::Migration[7.2]
  def change
    create_table :relationships do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users } # 外部キー設定を追加
      t.references :followed, null: false, foreign_key: { to_table: :users } # 外部キー設定を追加

      t.timestamps
    end

    # 一意制約を追加
    add_index :relationships, [ :follower_id, :followed_id ], unique: true
  end
end
