class CleanTables < ActiveRecord::Migration
  def up
    remove_column :fb_likes, :created_time
    remove_column :fb_likes, :created_at
    remove_column :fb_likes, :updated_at

    remove_column :users, :created_at
    remove_column :users, :updated_at
  end

  def down
    add_column :fb_likes, :created_time, :datetime
    add_column :fb_likes, :created_at, :datetime
    add_column :fb_likes, :updated_at, :datetime

    add_column :users, :created_at, :datetime
    add_column :users, :updated_at, :datetime
  end
end
