class CreateFriendships < ActiveRecord::Migration
  def up
    create_table :friendships do |t|
      t.integer :user_id
      t.integer :friend_id
    end
  end

  def down
    drop_table :friendships
  end
end
