class CreateThingPaths < ActiveRecord::Migration
  def self.up
    create_table :thing_paths do |t|
      t.integer :node01
      t.integer :node02
      t.integer :node03
      t.integer :node04
      t.integer :node05
      t.integer :node06
      t.integer :node07
      t.integer :node08
      t.integer :node09
      t.integer :node10
      t.integer :node11
      t.integer :node12
      t.integer :node13
      t.integer :node14
      t.integer :node15
      t.integer :node16
      t.integer :node17
      t.integer :node18
      t.integer :node19
      t.integer :node20
      t.timestamps
    end
  end

  def self.down
    drop_table :thing_paths
  end
end
