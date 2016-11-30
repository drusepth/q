class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
      t.references :phrasing, index: true, foreign_key: true
      t.string :seen_at

      t.timestamps null: false
    end
  end
end
