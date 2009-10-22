class Relationship < ActiveRecord::Base
  belongs_to :src_thing, :class_name=> "Thing", :foreign_key=>'src_thing_id'
  belongs_to :dest_thing, :class_name=> "Thing", :foreign_key=>'dest_thing_id'
  belongs_to :relationship_type
end
