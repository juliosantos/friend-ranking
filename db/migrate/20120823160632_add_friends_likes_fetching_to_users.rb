class AddFriendsLikesFetchingToUsers < ActiveRecord::Migration
  def change
    add_column :users, :friends_likes_fetching, :boolean, :default => false
  end
end
