class AddSourceToAnswer < ActiveRecord::Migration
  def change
    add_column :answers, :source, :string
  end
end
