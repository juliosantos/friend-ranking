class CreateLikesAndFbLikes < ActiveRecord::Migration
  def up
    create_table :fb_likes do |t|
      t.string :fb_id
      t.string :name
      t.string :category
      t.datetime :created_time # when did the user like this

      t.timestamps
    end

    create_table :likes do |t|
      t.references :user
      t.integer :likee_id
      t.string :likee_type
    end
  end

  def down
    drop_table :fb_likes
    drop_table :likes
  end
end
