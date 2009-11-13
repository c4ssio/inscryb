class ConvertUsersToCreators < ActiveRecord::Migration
  def self.up
    r_id = RelationshipType.find_or_create_by_value('creator').id
    Thing.find(:all).select{|th| th.user_id && th.user_id > 1 }.each do |th|
      UserThing.find_or_create_by_user_id_and_thing_id_and_relationship_type_id(
      th.user_id,th.id,r_id
      )
    end
    remove_column :things, :user_id
    rename_column :tags, :user_id, :creator_id
  end

  def self.down
  end
end
