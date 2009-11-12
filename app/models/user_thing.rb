class UserThing < ActiveRecord::Base
  belongs_to :user
  belongs_to :thing
  belongs_to :relationship_type
end
