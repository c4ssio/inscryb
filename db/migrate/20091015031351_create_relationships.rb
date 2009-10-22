class CreateRelationships < ActiveRecord::Migration
  def self.up
    create_table :relationships do |t|
      t.integer :src_thing_id, :null=>false
      t.integer :dest_thing_id, :null=>false
      t.integer :relationship_type_id, :null=>false
      t.timestamps
    end
  end

  def self.down
    begin; drop_table :relationships; rescue; end
  end
end
