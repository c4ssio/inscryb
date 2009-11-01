class AddUserColumns < ActiveRecord::Migration
  def self.up
    add_column :tags, :user_id, :integer, :default => 1
    add_column :things, :user_id, :integer, :default => 1
  end

  def self.down
  end
end
