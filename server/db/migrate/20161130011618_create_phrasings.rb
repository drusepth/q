class CreatePhrasings < ActiveRecord::Migration
  def change
    create_table :phrasings do |t|
      t.references :question, index: true, foreign_key: true
      t.string :phrasing

      t.timestamps null: false
    end
  end
end
