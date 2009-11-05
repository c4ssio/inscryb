class OldTag < ActiveRecord::Base
  belongs_to :thing

  def value
    #returns whatever value is not null
    [:term,:blurb,:number,:date].each {|v|
     return self[v] if self[v]
    }
  end

  def revert(args={})
    #re-attaches the tag
    if self.key=='parent_id'
      self.thing_id.th.at(:in=>self.number.to_i,:creator_id=>(args[:creator_id] || 1))
    else
      self.thing_id.th.at(self.key.to_sym => self.value,:creator_id=>(args[:creator_id] || 1))
    end
  end

end
