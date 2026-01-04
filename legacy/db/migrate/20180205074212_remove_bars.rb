class RemoveBars < ActiveRecord::Migration[5.1]
  def up
    drop_table :bars
  end
end
