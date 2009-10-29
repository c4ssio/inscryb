class CreateClipboardMembers < ActiveRecord::Migration
  def self.up
    create_table :clipboard_members do |t|
      t.integer :user_id
      t.integer :thing_id
      t.integer :tag_id
      t.integer :operation_id
      t.timestamps
    end
  end

  def self.down
    drop_table :clipboard_members
  end
end
