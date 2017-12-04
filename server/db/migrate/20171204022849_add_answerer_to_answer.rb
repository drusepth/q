class AddAnswererToAnswer < ActiveRecord::Migration
  def change
    add_column :answers, :answerer, :string
  end
end
