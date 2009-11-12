class RelsToUserThings < ActiveRecord::Migration
  def self.up
    rename_table :relationships,:user_things
    rename_column :user_things, :src_thing_id, :user_id
    rename_column :user_things, :dest_thing_id, :thing_id
    change_column :user_things, :relationship_type_id,:integer, :default=>1
    RelationshipType.find_or_create_by_value('owner')
  end

  def self.down
  end
end
