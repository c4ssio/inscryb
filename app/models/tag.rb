class Tag < ActiveRecord::Base
  belongs_to :thing

  define_index do
    has :user_id
    has :key
    has :term
    indexes :key
    indexes :term
    indexes :blurb
    indexes :number
    indexes :date
  end

  def self.find_by_value(value)
    #finds tags that have the appropriate value
    #prepare value condition
    value_cond = value.tag_value_type
    value_cond += (value_cond=='number' ? "=#{value}" : "='#{value}'" )

    #find all tags meeting these conditions
    return Tag.find(:all,:conditions=>value_cond)

  end

  def value
    #returns whatever value is not null
    [:term,:blurb,:number,:date].each {|v|
     return self[v] if self[v]
    }
  end


end