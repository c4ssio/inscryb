class CreateRelationshipTypes < ActiveRecord::Migration
  def self.up
    create_table :relationship_types do |t|
      t.string :value, :limit=>30
    end
  end

  def self.down
    begin;drop_table :relationship_types;rescue;end
  end
end
