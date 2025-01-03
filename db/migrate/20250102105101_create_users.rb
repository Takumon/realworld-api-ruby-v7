class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false, comment: "メールアドレス(重複不可)"
      t.string :username, null: false, comment: "ユーザー名(氏名)"
      t.string :password_digest, comment: "パスワード(暗号化して保存)"
      t.text :bio, comment: "自己紹介文"
      t.string :image, comment: "プロフィール画像"
      t.integer :lock_version, default: 0, null: false, comment: "楽観的ロック用のカラム"

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
