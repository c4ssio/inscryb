class AddStartingData < ActiveRecord::Migration
  def self.up
    DefaultData.add_starting_data
    Thing.import(Rails.root.to_s + '/lib/test_data.txt')
  end

  def self.down

  end
end
