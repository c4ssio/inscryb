class Thing < ActiveRecord::Base
  
  has_one :user_thing
  has_many :tags
  has_many :old_tags
  belongs_to :parent, :class_name=>'Thing',:foreign_key=>'parent_id'
  belongs_to :place
  has_many :children, :class_name=>'Thing',:foreign_key=>'parent_id'

  attr_accessor :child_matches
  attr_accessor :is_match
  attr_accessor :key
  attr_accessor :value

  #for sphinx search engine
  define_index do
    #sphinx fields
    indexes :name
    has :parent_id
    indexes tags.key
    indexes tags.term
    indexes tags.blurb
  end

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

  def copy_children_and_tags_by_dest_and_user(dest_id,user_id)
    #args here is :dest, which specifies the thing id under which self should be copied
    self_pth = self.id.pth
    depth=(self_pth ? self_pth.nodes.length + 1 : 0)

    #first child of thing_map is self and dest
    @thing_map = [{:src_id=>self.id,:dest_id=>dest_id}]
    #all paths used here except self
    @src_paths = self.paths.select{|p| p.target!=self.id}

    @src_paths.each do |sp|
      #for each child of the source path that is deeper than self,
      #check for a dest path in thing_map and copy any that have not been copied yet
      Array(depth..20).each do |n|
        sth_id = sp.node(n)
        if sth_id && !@thing_map.collect{|r| r[:src_id]}.include?(sth_id)
          sth = sth_id.th
          dth = sth.copy_by_user(user_id); dth.parent_id = nil; dth.save!
          @thing_map << {:src_id=>sth.id,:dest_id=>dth.id}
          #assign parent as dth corresponding to parent
          dth.at(:in=>@thing_map.select{|r|
              r[:src_id]==sth.parent_id}[0][:dest_id])
        end
      end
      #add target to map table
      sth = sp.target.th
      #strip parent from copy
      dth = sth.copy_by_user(user_id); dth.save!
      #assign parent as dth corresponding to parent
      dth.at(:in=>@thing_map.select{|r|
          r[:src_id]==sth.parent_id}[0][:dest_id])
      #add copy to map
      @thing_map << {:src_id=>sth.id,:dest_id=>dth.id}
    end

    #take tags and assign to dest thing
    self.tags.each do |stg|
      dtg = stg.clone
      dtg.thing_id = dest_id
      dtg.save!
    end

  end

  def copy_by_user(user_id)

    dth = self.clone
    dth.save!
    dth.add_creator(user_id)

    self.tags.each do |stg|
      dtg = stg.clone
      dtg.thing_id = dth.id
      dtg.creator_id = user_id
      dtg.save!
    end

    return dth
  end

  def add_creator(user_id)
    UserThing.find_or_create_by_user_id_and_thing_id_and_relationship_type_id(
      user_id, self.id,RelationshipType.find_or_create_by_value('creator').id
    )
  end

  def get_child_matches(search_str)
    if (!search_str || search_str=="") then
      @child_matches = []
    else
      @all_matches = Thing.search(search_str,:without=>{:parent_id=>0},:per_page=>1000).collect{|th| th.id}
      @child_matches = self.paths.select{|chpth|
        @all_matches.include?(chpth.target)}
    end
    #length+2: +1 to get to actual thing's depth, +1 to get to child depth
    child_depth_str = (self.parent_nodes.length+2).to_s.rjust(2,'0')
    self.children.each do |m|
      m.child_matches=@child_matches.select{|mm|
        eval("mm.node#{child_depth_str}==#{m.id}")}.collect{|mm| mm.target.th }
      m.is_match=true if @child_matches.collect{|mm| mm.target}.include?(m.id)
    end
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

  def add_type_by_user(type,user_id)
    candidates = Tag.find_all_by_key_and_term('type',type).select{|tg|
      tg.thing_id.pth && tg.thing_id.pth.node01==1}.collect{|tg|
      tg.thing}
    if !candidates.empty?
      #copy all tags and children from simplest candidate
      not_parents = candidates.select{|c| !self.parent_nodes.include?(c.id)}
      least_complex = not_parents.sort_by{|c| c.paths.length + c.tags.length}[0]
      least_complex.copy_children_and_tags_by_dest_and_user(self.id,user_id)
    else
      #simply add type
      self.at(:type=>type, :creator_id => @creator_id)
    end

  end
 
  def add_tags(args)
    #args is a hash, with values that may be either single values or arrays of values
    #takes an optional creator argument that adds a creator row into user_things table
    keys = Hash.new

    keys[:child] = TermGroup.fbn('thing_key_child').members

    keys[:parent] = TermGroup.fbn('thing_key_parent').members

    #identifies user
    @creator_id = args[:creator_id]
    args.delete(:creator_id) if args[:creator_id]

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
          #create a new child beneath parent_id
          if !(v.to_i.to_s == v.to_s) or v == '0'
            new_parent = Thing.create
            #add creator relationship for thing
            new_parent.add_creator(@creator_id) if @creator_id
            new_parent.at(:name=>v.to_s, :creator_id => @creator_id)
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
          #create a new child beneath self
          if !(v.to_i.to_s == v.to_s) or v == '0'
            #try to find another thing with the same name
            new_child = Thing.create
            new_child.add_creator(@creator_id ) if @creator_id
            new_child.at(:in=>self.id,:creator_id=>@creator_id)
            new_child.at(:name=>v.to_s, :creator_id=>@creator_id)
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
          if self.name
            self.dt(k.to_sym) if self.name != v
          else
            #add name as a type
            self.add_type_by_user(v.to_s,@creator_id)
          end
          self.name = v.to_s.gsub("'","\'")
          self.save!
        elsif k=="address"
          #delete previous address, lng, and lat
          self.dt(:coded_addr);self.dt(:longitude);self.dt(:latitude)
          #replacing '&' with 'and' for geocoding purposes
          geo_rml=Geocoding.get( v.gsub('&',' and '))[0]
          #if latitude and longitude is found, use first result
          if geo_rml
            self.at(:longitude=>geo_rml[:longitude], :creator_id => @creator_id)
            self.at(:latitude=>geo_rml[:latitude], :creator_id => @creator_id)
            self.at(:coded_addr=>(geo_rml[:thoroughfare]+ ', ' +
                  geo_rml[:administrative_area] + ', ' +
                  geo_rml[:postal_code]) , :creator_id => @creator_id)
          end
        else
          #if key is neither parent, child, or name include it in the tags table
          #add simple text address to tags
          if v.tag_value_type=="term"
            Tag.find_or_create_by_thing_id_and_key_and_term_and_creator_id(
              self.id,k,v,@creator_id)
          elsif v.tag_value_type=="blurb"
            Tag.find_or_create_by_thing_id_and_key_and_blurb_and_creator_id(
              self.id,k,v,@creator_id)
          elsif v.tag_value_type=="date"
            Tag.find_or_create_by_thing_id_and_key_and_date_and_creator_id(
              self.id,k,v,@creator_id)
          elsif v.tag_value_type=="number"
            Tag.find_or_create_by_thing_id_and_key_and_number_and_creator_id(
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

    #identifies user
    @creator_id ||=(args[:creator_id] || 1)
    args.delete(:creator_id) if args[:creator_id]


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
            OldTag.find_or_create_by_thing_id_and_key_and_fixnum_and_created_at_and_user_id(
              self.id,"parent_id",self.parent_id,self.created_at,@creator_id)
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
            OldTag.find_or_create_by_thing_id_and_key_and_fixnum_and_created_at_and_user_id(
              @th_oth.id,"parent_id",@th_oth.parent_id,self.created_at,@creator_id)
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
            OldTag.find_or_create_by_thing_id_and_key_and_term_and_created_at_and_user_id(
              self.id,"name",self.name,self.created_at,@creator_id)
            self.name = nil
            self.save!
          end
        else

          #find all tags meeting these conditions
          @curr_tags=Tag.find(:all,:conditions=>
              {:thing_id=>self.id, :key=>k,
              v.tag_value_type.to_sym=>v})

          #move each tag into the OldTag table
          @curr_tags.each do |t|
            OldTag.find_or_create_by_thing_id_and_key_and_term_and_blurb_and_number_and_date_and_created_at_and_user_id(
              self.id,t.key,t.term,t.blurb,t.number,t.date,t.created_at,@creator_id
            )
            t.delete
          end
        end
      end
    end
    
  end

  #these are all aliases for methods above, to allow for shorthand

  def fv(key=nil)
    return self.find_values(key)
  end

  def at(args)
    return add_tags(args)
  end

  def self.i(args)
    return self.import(args)
  end

  def dt(args)
    return delete_tags(args)
  end

  def s_rels
    return self.src_relationships
  end

  def d_rels
    return self.dest_relationships
  end

end