class User < ActiveRecord::Base
  has_many :clipboard_members
end
