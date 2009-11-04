class Thing < ActiveRecord::Base
  
  has_many :src_relationships, :class_name=>'Relationship',:foreign_key=>'src_thing_id'
  has_many :dest_relationships, :class_name=>'Relationship',:foreign_key=>'dest_thing_id'
  has_many :tags
  has_many :old_tags
  belongs_to :parent, :class_name=>'Thing',:foreign_key=>'parent_id'
  has_many :members, :class_name=>'Thing',:foreign_key=>'parent_id'

  #for sphinx search engine
  define_index do
    #sphinx fields
    indexes :name
    indexes tags.key
    indexes tags.term
    indexes tags.blurb
  end

  attr_accessor :matches
  attr_accessor :is_match
  
  def parent_nodes
    path=[]
    parent_id = self.parent_id
    while !parent_id.nil?
      path=[parent_id] + path if !parent_id.nil?
      parent_id=parent_id.th.parent_id
    end
    return path
  end

  def paths
    #get depth of self as parent
    self_pth = self.id.pth
    depth=(self_pth ? self_pth.nodes.length + 1 : 0)
    return [] if depth == 0
    return [self_pth] + eval("ThingPath.find_all_by_node#{depth.to_s.rjust(2,'0')}(#{self.id.to_s})")
  end

  def create_path
    parent_nodes = self.parent_nodes

    #determine whether other paths exist under this thing
    #with a different path and updates them
    self.paths.each do |pth|
      old_nodes = pth.nodes
      if pth.target == self.id
        child_nodes = []
      else
        child_nodes = old_nodes[old_nodes.index(self.id)..20]
      end

      #new path consists of new self path + whatever path the child had after self
      new_path=parent_nodes + child_nodes
      i=1
      new_path.each do |n|
        pth.set_node(i,n)
        i+=1
      end
      #null out remaining nodes
      (i..20).each do |j|;pth.set_node(j,nil);end
      pth.save!
    end

    #if self path already exists this part will do nothing
    #args include target and parent path
    args = [self.id] + parent_nodes
    #find or create new paths
    method_string = "ThingPath.find_or_create_by_target"

    #add nodes to method string
    i=1
    args.length.times {method_string += "_and_node" + i.to_s.rjust(2,'0').to_s;i+=1}
    #add arguments to method string
    method_string += "(#{args.join(',')})"
    #evaluate method string
    eval(method_string)

  end

  def copy_members_and_tags_to(args)
    #args here is :dest, which specifies the thing id under which self should be copied
    self_pth = self.id.pth
    depth=(self_pth ? self_pth.nodes.length + 1 : 0)

    @thing_map = Array.new
    @src_paths = self.paths.select{|p| p.target != self.id}

    #add all targets to map table
    @src_paths.each do |sp|
      sth = sp.target.th
      #strip parent from copy
      dth = sth.copy; dth.parent_id = nil; dth.save!
      #add copy to map
      @thing_map << {:src_id=>sth.id,:dest_id=>dth.id}
    end

    #go through map and reassign parents for all but direct descendants
    @thing_map.select{|r| r[:src_id].th.parent!=self }.each do |r|
      dth = r[:dest_id].th
      dth.parent_id = @thing_map.select{|rd| r[:src_id].th.parent_id==rd[:src_id]}[0][:dest_id]
      dth.save!
    end

    #generate paths for each
    @src_paths.each do |sp|
      dp = sp.clone
      dp.target = @thing_map.select{|r| r[:src_id]==sp.target}[0][:dest_id]
      if depth>0
        Array(1..(depth-2)).reverse.each do |n|
          dp.set_node(n,nil)
        end
        (depth..20).each do |n|
          new_node = @thing_map.select{|r| r[:src_id]==dp.node(n)}[0]
          dp.set_node(n, new_node[:dest_id]) unless new_node.nil?
        end
      end
      dp.save!
    end

    #take direct descendants and assign to dest thing
    @thing_map.select{|r| r[:src_id].th.parent==self }.each do |r|
      args[:dest].th.at(:has=>r[:dest_id])
    end

    #take tags and assign to dest thing
    self.tags.each do |stg|
      dtg = stg.clone
      dtg.thing_id = args[:dest]
      dtg.save!
    end

  end

  def copy_to(args)
    #args here is :dest, which specifies the thing id under which self should be copied
    self_pth = self.id.pth
    depth=(self_pth ? self_pth.nodes.length + 1 : 0)

    @thing_map = Array.new
    @src_paths = self.paths

    #add all targets to map table
    @src_paths.each do |sp|
      sth = sp.target.th
      #strip parent from copy
      dth = sth.copy; dth.parent_id = nil; dth.save!
      #add copy to map
      @thing_map << {:src_id=>sth.id,:dest_id=>dth.id}
    end

    dself_id = @thing_map.select{|r| r[:src_id]==self.id}[0][:dest_id]

    #go through map and reassign parents for all but main
    @thing_map.select{|r| r[:dest_id]!=dself_id }.each do |r|
      dth = r[:dest_id].th
      dth.parent_id = @thing_map.select{|rd| r[:src_id].th.parent_id==rd[:src_id]}[0][:dest_id]
      dth.save!
    end

    #generate paths for each
    @src_paths.each do |sp|
      dp = sp.clone
      dp.target = @thing_map.select{|r| r[:src_id]==sp.target}[0][:dest_id]
      if depth>0
        Array(1..(depth-2)).reverse.each do |n|
          dp.set_node(n,nil)
        end
        (depth..20).each do |n|
          new_node = @thing_map.select{|r| r[:src_id]==dp.node(n)}[0]
          dp.set_node(n, new_node[:dest_id]) unless new_node.nil?
        end
      end
      dp.save!
    end

    #take top member corresponding to self on thing_map and add it to destination
    dself_id.th.at(:in=>args[:dest])

  end

  def copy

    dth = self.clone
    dth.save!

    self.tags.each do |stg|
      dtg = stg.clone
      dtg.thing_id = dth.id
      dtg.save!
    end

    return dth
  end

  def self.import(args)
    #this is used for importing data files. Used by the add_starting_data migration
    
    #begin
      
    # opens the first file for reading
    myfile = File.open(args,'r')
      
    thing_cnt=0
    total_row_count=1
    line_count=0
    row_cnt=0
      
    tag_keys = Array.new
    values = Array.new
    # Reading the first line and splitting it
    first_line=myfile.gets
      
    # find out whether the delimiter type is "|" or "\t"
    delimiter_type = first_line.index('|')
    delimiter_type == nil ? delimiter="\t" : delimiter="|"
      
    # opens the second file for writing
    File.open(args.gsub('.txt','')+'_output.txt', 'w') { |f|
      f.puts first_line
      myfile.each {|line|
          
        total_row_count +=1
        values = line.split(delimiter)
          
        # New thing Id to be added
        if line.strip != ""
          if (values[0].to_i==0)
            @th=Thing.create(:user_id =>
                @creator_id )
            thing_cnt +=1
            f.puts @th.id.to_s+line
          end
        end
      }
    }
    # opens the second file for reading
    myfile = File.open(args.gsub('.txt','')+'_output.txt','r')
    first_line=myfile.gets
    # separating the keys
    tag_keys = first_line.gsub("\n","").split(delimiter)

    myfile.each {|line|
      line_count += 1
      values = line.split(delimiter)
      # finding the thing id for adding tags to it
      @th=Thing.find(values[0])
      row_cnt =1
        
      for i in 1..values.length-1 do
        if(values[i].strip!="")
          values[i]=values[i].gsub('"','')
          # to find if the value is a float number
          check_float= /\A[+-]?\d+?(\.\d+)?\Z/
          if check_float.match(values[i])
            if /[.]/.match(values[i])
              values[i]=values[i].to_f
            else
              values[i]=values[i].to_i
            end
          else
            values[i]=values[i].gsub("\n","")
          end
            
          # if the value field is a Row No.
          if values[i].to_s[0..2]=="ROW"
            # to find if a parent row is referred which comes after child row
            if line_count <= values[i].to_s.split("ROW")[1].to_i
              raise "Thing #{values[0]}: parent row inserted after child row"
            end
            # opening the second file again to find out the thing id corresponding to the row no.
            myfile_second = File.open(args.gsub('.txt','')+'_output.txt','r')
            row_cnt=1
            myfile_second.each {|line|
              # find out the number part from ROW#
              number_part = values[i].to_s.split("ROW")[1].to_i + 1
              if number_part.to_i > total_row_count
                raise "row number greater than file row count"
              end
              # If the corresponding row is found
              if  row_cnt == number_part.to_i
                  
                values1 = line.split(delimiter)
                @th.add_tags(tag_keys[i].to_sym => values1[0].to_i)
                flag = 1
              end
              row_cnt +=1
              flag == 1 ? break : ''
            }
            myfile_second.close
          else
            @th.add_tags(tag_keys[i].to_sym => values[i])
          end
            
        end
      end
    }
    myfile.close
      
    #rescue Exception => e
    #      puts "Row: #{row_cnt+1}  "+ e.message
    # puts  e.message
    #end
    
    puts "No. of things created : #{thing_cnt}"
  end
 
  def add_tags(args)
    #args is a hash, with values that may be either single values or arrays of values
    keys = Hash.new

    keys[:child] = TermGroup.fbn('thing_key_child').members

    keys[:parent] = TermGroup.fbn('thing_key_parent').members

    #identifies user
    @creator_id ||=(args[:creator_id] || 1)
    args.delete(:creator_id)

    args.each do |ksym,v|

      #store key and value for these tags;
      #convert key to downcased string for use in database searches
      #convert value to array to allow all values to be treated as arrays,
      #since array is a permitted input. single inputs will be treated as 1-member arrays
      k = ksym.to_s.downcase
      va = Array(v)

      va.each do |v|
        if keys[:child].include?(k)
          #if use supplies a string rather than an integer
          #create a new member beneath parent_id and put child under it
          if v.to_i.to_s != v.to_s or v == '0'
            new_parent = Thing.create(:user_id =>
                @creator_id )
            new_parent.at(:name=>v.to_s)
            new_parent.at(:in=>self.parent_id)
            self.at(:in=>new_parent.id)
          else
            #if user tries to add thing as child of child, fail:
            raise "can't add parent as child" if v.th.parent_nodes.include?(self.id)
            raise "can't add self as child" if v.to_i == self.id
            # if the key term is a member of thing_key_child and child is marked as having a different
            # parent, delete that tag; then add self as new parent
            id.th.dt(k.to_sym) if self.parent_id && self.parent_id != v
            self.parent_id = v
            self.save!
            #create paths for this new relationship
            self.create_path
          end
        elsif keys[:parent].include?(k)
          #if use supplies a string rather than an integer
          #create a new member beneath self
          if v.to_i.to_s != v.to_s or v == '0'
            #try to find another thing with the same name
            candidates = (@creator_id >1 ? Thing.find_all_by_name(v.to_s) : nil)
            if candidates && !candidates.empty?
              not_parents = candidates.select{|c| !self.parent_nodes.include?(c.id)}
              most_complex = not_parents.sort_by{|c| c.paths.length}.last
              new_child = most_complex.copy_to(:dest=>self.id)
            else
              new_child = Thing.create(:user_id =>
                  @creator_id )
              new_child.at(:name=>v.to_s)
              new_child.at(:in=>self.id)
            end
          else
            # do the opposite for parent version
            #if user tries to add thing as parent of parent, fail:
            raise "can't add child as parent" if self.parent_nodes.include?(v)
            raise "can't add self as parent" if v.to_i == self.id
            self.dt(k.to_sym) if v.th.parent_id && v.th.parent_id != self.id
            @th_oth = v.th
            @th_oth.parent_id = self.id
            @th_oth.save!
            #create paths for this new relationship
            @th_oth.create_path
          end
        elsif k=="name" 
          self.dt(k.to_sym) if self.name && self.name != v
          self.name = v
          self.save!
        else
          #if key is neither parent, child, or name include it in the tags table

          #if key is address get geocoding info
          if k=="address"
            #delete previous address, lng, and lat
            self.dt(:address);self.dt(:longitude);self.dt(:latitude)
            #replacing '&' with 'and' for geocoding purposes
            geo_rml=Geocoding.get( v.gsub('&',' and ') )
            
            #if latitude and longitude is found
            if geo_rml.length == 1
              self.at(:longitude=>geo_rml[0][8])
              self.at(:latitude=>geo_rml[0][9])
            end
          #if key is type, find most complex non-parent type and add members and tags
          elsif k=='type'
            #try to find another thing with the same type
            if @creator_id > 1
            candidates = Tag.search('type ' + v.to_s).select{|tg|
              tg.term == v.to_s
            }.collect{|tg| tg.thing}
              if !candidates.empty?
                not_parents = candidates.select{|c| !self.parent_nodes.include?(c.id)}
                most_complex = not_parents.sort_by{|c| c.paths.length}.last
                most_complex.copy_members_and_tags_to(:dest=>self.id)
              end
            end
            #delete self same tag to avoid dupes
            self.dt(k.to_sym => v.to_s)
          end

          #add simple text address to tags
          if v.tag_value_type=="term"
            Tag.find_or_create_by_thing_id_and_key_and_term_and_user_id(
              self.id,k,v,@creator_id)
          elsif v.tag_value_type=="blurb"
            Tag.find_or_create_by_thing_id_and_key_and_blurb_and_user_id(
              self.id,k,v,@creator_id)
          elsif v.tag_value_type=="date"
            Tag.find_or_create_by_thing_id_and_key_and_date_and_user_id(
              self.id,k,v,@creator_id)
          elsif v.tag_value_type=="number"
            Tag.find_or_create_by_thing_id_and_key_and_number_and_user_id(
              self.id,k,v,@creator_id)
          else
            raise "unknown tag_value type"
          end
        end
      end
    end
  end
  
  def delete_tags(args)
    #creates rows in the old_tags table and deletes fields from the things and rows from tags tables
    #accepts single symbol (key) or hashes; single symbol deletes all tags with that key

    keys = Hash.new
    keys[:child] = TermGroup.fbn('thing_key_child').members
    keys[:parent] = TermGroup.fbn('thing_key_parent').members

    #if user has provided only a symbol, fill it out to produce hash
    if args.class == Symbol
      ksym = args
      k = args.to_s
      #create a hash composed of all possible values
      if keys[:child].include?(k)
        args = {ksym => self.parent_id}
      elsif keys[:parent].include?(k)
        args = {ksym => Thing.find(:all,:conditions=>"parent_id=#{self.id}").collect{ |th| th.id } }
      elsif k=="name"
        args = {ksym => self.name}
      else
        args = {ksym => Tag.find(:all,:conditions=>"thing_id=#{self.id} and tags.key='#{k}'").collect{ |tg| tg.value } }
      end
    end

    #with any symbols converted to hashes, go through hash and perform deletions

    args.each do |ksym,v|
      #store key and value for these tags;
      #convert key to string for use in database searches
      #convert value to array to allow all values to be treated as arrays,
      #since array is a permitted input. single inputs will be treated as 1-member arrays
      k = ksym.to_s
      va = Array(v)

      va.each do |v|

        if keys[:child].include?(k)
          if self.parent_id == v
            OldTag.find_or_create_by_thing_id_and_key_and_number_and_created_at(
              self.id,"parent_id",self.parent_id,self.created_at)
            self.parent_id = nil
            self.save!
            #nil out nodes on all paths down to and
            #including parent path
            self.paths.each{|chpth|
              n=1
              while chpth.node(n)!=v
                chpth.set_node(n,nil)
                n+=1
              end
              #nil parent node
              chpth.set_node(n,nil)
              chpth.save!
            }
          end
        elsif keys[:parent].include?(k) 
          if v.th.parent_id == self.id
            @th_oth = v.th
            OldTag.find_or_create_by_thing_id_and_key_and_number_and_created_at(
              @th_oth.id,"parent_id",@th_oth.parent_id,self.created_at)
            @th_oth.parent_id = nil
            @th_oth.save!
            #nil out nodes on all paths down to and
            #including parent path
            @th_oth.paths.each{|chpth|
              n=1
              while chpth.node(n)!=self.id
                chpth.set_node(n,nil)
                n+=1
              end
              #nil parent node
              chpth.set_node(n,nil)
              chpth.save!
            }
          end
        elsif k=="name" 
          if self.name==v
            OldTag.find_or_create_by_thing_id_and_key_and_term_and_created_at(
              self.id,"name",self.name,self.created_at)
            self.name = nil
            self.save!
          end
        else
          #prepare value condition
          value_cond = v.tag_value_type
          value_cond += (value_cond=='number' ? "=#{v}" : "='#{v}'" )

          #find all tags meeting these conditions
          @curr_tags=Tag.find(:all,:conditions=>
              "thing_id=#{self.id} and tags.key='#{k}' and " + value_cond)

          #move each tag into the OldTag table
          @curr_tags.each do |t|
            OldTag.find_or_create_by_thing_id_and_key_and_term_and_blurb_and_number_and_date_and_created_at(
              self.id,t.key,t.term,t.blurb,t.number,t.date,t.created_at
            )
            t.delete
          end
        end
      end
    end
    
  end
  
  def find_values(key=nil)
    #returns a simple array of values for a given key
    #easy way to determine if a thing has the desired tag, or to collect all tags of a certain type

    if key.nil?
      #returns simply all values sorted by order
      return self.thing_tags.sort_by{|tht| tht.id}.collect{|tht| tht.tag.value}
    end
    
    #returns an array of values for each tag the Thing has matching the key
    return self.thing_tags.select{|tht|
      tht.tag.key==key.to_s}.sort_by{|tht|
      tht.id}.collect{|tht|
      tht.tag.value}


  end

  #these are all aliases for methods above, to allow for shorthand

  def fv(key=nil)
    return self.find_values(key)
  end

  def at(args)
    return add_tags(args)
  end

  def fr(args={},s=20, d=1, p=self.id)
    return find_related(args,s, d, p)
  end

  def self.i(args)
    return self.import(args)
  end

  def self.fbt(args)
    return self.find_by_tags(args)
  end

  def dt(args)
    return delete_tags(args)
  end

  def tg
    return self.tags
  end

  def s_rels
    return self.src_relationships
  end

  def d_rels
    return self.dest_relationships
  end

  #this method is meant to be human readable, not used in other methods;
  #used to show all tags for given thing
  def lt #list_tags
    #create hash for result
    self.thing_tags.sort_by{|tht|
      tht.id}.each do |tht|
      off_at = tht.off_at.nil? ? '' : ' (off at ' + tht.off_at.to_s + ')'
      puts  ':' + tht.tag.get_key_and_value.keys[0].to_s + ' => ' +
        tht.tag.get_key_and_value.values[0].to_s +
        off_at
    end
    return nil
  end


end