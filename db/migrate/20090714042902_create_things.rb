class CreateThings < ActiveRecord::Migration
  def self.up
    create_table :things do |t|
      t.string :name, :limit=>30
      t.integer :thing_type_id
      t.integer :parent_id
      t.timestamps
    end
  end

  def self.down
    begin drop_table :things;rescue; end
  end
end
