class AddUserIdToOldTags < ActiveRecord::Migration
  def self.up
    add_column :old_tags, :user_id, :integer, :default => 1
  end

  def self.down
  end
end
