class Place < ActiveRecord::Base
  has_many :things
  define_index do
    #sphinx fields
    indexes :guid
  end

end
