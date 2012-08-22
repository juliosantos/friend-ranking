class AddIndexesToFbLikes < ActiveRecord::Migration
  def up
    add_index :fb_likes, :fb_id
  end

  def down
    remove_index :fb_likes, :fb_id
  end
end
