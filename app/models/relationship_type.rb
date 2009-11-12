class RelationshipType < ActiveRecord::Base
  has_many :user_things
end
