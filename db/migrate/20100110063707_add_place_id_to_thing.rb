class AddPlaceIdToThing < ActiveRecord::Migration
  def self.up
    add_column :things, :place_id, :integer
  end

  def self.down
  end
end
