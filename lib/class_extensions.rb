  class String
    def tag_value_type
      if !(begin;self.to_date;rescue;nil; end).nil?
        return "date"
      elsif self.length<=30
        return "term"
      elsif self.length<=255
        return "blurb"
      else
        return "none"
      end
    end
  end
  class Fixnum
    def tag_value_type
      return "number"
    end
    def th
      return Thing.find(self)
    end
    def trg
      return TermGroup.find(self)
    end
    def trgm
      return TermGroupMember.find(self)
    end
    def tg
      return Tag.find(self)
    end
    def rel
      return Relationship.find(self)
    end
    def pth
      return ThingPath.find_by_target(self)
    end
  end
  class BigDecimal
    def tag_value_type
      return "number"
    end
  end
  class Float
    def tag_value_type
      return "number"
    end
  end
  class Numeric
    def to_rad
      self * Math::PI / 180 
    end
  end
  class Hash
    def list
      self.each do |h|
        puts ":" + h[0].to_s + " => " + h[1].to_s
      end
      return nil
    end
  end
  class Array
    def list
      a=0
      self.length.times do |a|
        puts a.to_s + ": " + self[a].to_s
        a+=1
      end
      return nil
    end
  end