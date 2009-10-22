class CreateThingTypes < ActiveRecord::Migration
  def self.up
    create_table :thing_types do |t|
      t.string :value, :limit=>30, :null=>false
    end
  end

  def self.down
    begin;drop_table :thing_types;rescue;end
  end
end
