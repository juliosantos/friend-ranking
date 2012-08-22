class AddUnicornsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :unicorns, :boolean, :default => false
  end
end
