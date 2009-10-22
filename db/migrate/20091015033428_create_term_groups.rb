class CreateTermGroups < ActiveRecord::Migration
  def self.up
    create_table :term_groups do |t|
      t.string :name, :null=>false
    end
  end

  def self.down
    drop_table :term_groups
  end
end
