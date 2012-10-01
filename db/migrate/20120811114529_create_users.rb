class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :first_name
      t.string :facebook_uid
      t.string :access_token

      t.timestamps
    end
  end
end
