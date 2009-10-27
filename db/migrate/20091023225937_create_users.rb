class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, :limit=>30
      t.string :password_hash
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
