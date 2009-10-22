class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
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
    begin drop_table :tags;rescue; end
  end
end
