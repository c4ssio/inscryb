class ClipboardMember < ActiveRecord::Base
  belongs_to :user
  belongs_to :thing
end
