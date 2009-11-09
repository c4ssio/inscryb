class ThingPath < ActiveRecord::Base
  def nodes
    result_array = []
    (1..20).collect{|i| i.to_s.rjust(2,'0')}.collect do |i|
      result_array << eval('self.node' + i)
    end
    #cut off nils from the right
    Array(0..19).reverse.each do |n|
      if result_array[n].nil?
        result_array.slice!(n)
      else
        break
      end
    end
    #if result_array is empty, check for a child that can identify depth
    if result_array.empty?
      @thing_child = Thing.find_by_parent_id(self.target)
      if @thing_child
        @thing_child.create_path unless @thing_child.id.pth
        result_array = @thing_child.id.pth.nodes[0..-2] if @thing_child
      end
    end
    return result_array
  end
  def node(index)
    return eval("self.node#{index.to_s.rjust(2,'0')}")
  end
  def set_node(index,value)
    value='nil' if value.nil?
    eval("self.node#{index.to_s.rjust(2,'0')}=#{value.to_s}")
  end
end
