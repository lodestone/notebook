class CreateLoreTowns < ActiveRecord::Migration[6.0]
  def change
    create_table :lore_towns do |t|
      t.references :lore, null: false, foreign_key: true
      t.references :town, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
  end
end
