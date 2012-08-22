class FbLike < ActiveRecord::Base
  has_many :likes, as: :likee
  has_many :users, through: :likes

  attr_accessible :fb_id, :name, :category, :created_time

  validates_uniqueness_of :fb_id
end
