class ThingPath < ActiveRecord::Base
  def nodes
    result_array = []
    (1..20).collect{|i| ('0' + i.to_s)[-2..-1]}.collect do |i|
      result_array << eval('self.node' + i) unless eval('self.node' + i).nil?
    end
    return result_array.flatten
  end
end
