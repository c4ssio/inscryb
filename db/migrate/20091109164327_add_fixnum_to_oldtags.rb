class AddFixnumToOldtags < ActiveRecord::Migration
  def self.up
    add_column :old_tags, :fixnum, :integer
  end

  def self.down
  end
end
