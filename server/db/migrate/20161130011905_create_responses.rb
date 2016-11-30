class CreateResponses < ActiveRecord::Migration
  def change
    create_table :responses do |t|
      t.references :question, index: true, foreign_key: true
      t.references :answer, index: true, foreign_key: true
      t.string :seen_at

      t.timestamps null: false
    end
  end
end
