class CreateTermGroupMembers < ActiveRecord::Migration
  def self.up
    create_table :term_group_members do |t|
      t.integer :term_group_id, :null=>false
      t.string :value, :limit=>30, :null=>false
    end
  end

  def self.down
    drop_table :term_group_members
  end
end
