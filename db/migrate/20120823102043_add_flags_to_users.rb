class AddFlagsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :friends_fetched, :boolean, :default => false
    add_column :users, :friends_likes_fetched, :boolean, :default => false
    add_column :users, :likes_fetched, :boolean, :default => false
  end
end
