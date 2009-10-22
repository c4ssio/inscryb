class TermGroup < ActiveRecord::Base
  has_many :term_group_members

  def self.add_members(args)
  #used to add values to a group, if values are not in it already
  #used in add_starting_data to define initial groups

    @tg = TermGroup.find_or_create_by_name(args[:name])

    args[:member].to_a.each { |m|
      TermGroupMember.find_or_create_by_term_group_id_and_value(@tg.id,m)
      }

    return @tg

  end

  def members
    #returns simple text array of members of specified group
    return self.term_group_members.collect{|m| m.value}
  end

  #aliases

  def self.fbn(args)
    return self.find_by_name(args)
  end


end
