class Like < ActiveRecord::Base
  belongs_to :user
  belongs_to :likee, polymorphic: true

  validates_uniqueness_of :likee_id, scope: [:user_id, :likee_type]
end
