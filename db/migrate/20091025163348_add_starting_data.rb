class AddStartingData < ActiveRecord::Migration
  def self.up
    DefaultData.add_starting_data
    Thing.import(Rails.root.to_s + '/lib/test_data.txt')
    User.find_or_create_by_name('inscryb')
    Operation.find_or_create_by_name('cut')
    Operation.find_or_create_by_name('copy')
  end

  def self.down

  end
end
