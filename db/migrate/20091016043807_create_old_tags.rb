class CreateOldTags < ActiveRecord::Migration
  def self.up
    create_table :old_tags do |t|
      t.integer :thing_id, :null => false
      t.string :key, :limit => 30, :null=> false
      t.string :term, :limit =>  30
      t.string :blurb, :limit =>  255
      t.decimal :number, :precision => 18, :scale => 15
      t.date :date
      t.timestamps
    end
  end

  def self.down
    drop_table :old_tags
  end
end
