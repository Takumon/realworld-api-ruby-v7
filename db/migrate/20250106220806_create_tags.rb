class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.string :name, null: false, comment: "タグ名"

      t.timestamps
    end

    add_index :tags, :name, unique: true
  end
end
