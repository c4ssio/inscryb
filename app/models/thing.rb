class Thing < ActiveRecord::Base
  
  has_many :src_relationships, :class_name=>'Relationship',:foreign_key=>'src_thing_id'
  has_many :dest_relationships, :class_name=>'Relationship',:foreign_key=>'dest_thing_id'
  belongs_to :thing_type
  has_many :tags
  has_many :old_tags
  belongs_to :parent, :class_name=>'Thing',:foreign_key=>'parent_id'

  #for sphinx search engine
  define_index do
    #sphinx fields
    indexes :name
    indexes tags.key
    indexes tags.term
    indexes tags.blurb
  end

  def parent_path
    path=[]
    parent_id = self.parent_id
    while !parent_id.nil?
      path=[parent_id] + path if !parent_id.nil?
      parent_id=parent_id.th.parent_id
    end
    return path
  end

  def child_thing_paths
    depth=ThingPath.find_by_target(self.id).nodes.length
    return [] if depth == 0
    return eval('ThingPath.find_all_by_node' + depth.to_s.rjust(2,'0'))
  end

  def create_thing_path
    expr_string = "ThingPath.find_or_create_by_target"
    i=1
    path = [self.id] + self.parent_path
    path.each do |n|
      node_string=("node" + i.to_s.rjust(2,'0'))
      expr_string += ("_and_" + node_string)
      i+=1
    end
    #ends at 20 since that is the max number of nodes
    j=i
    (i..20).each do
      node_string=("node" + j.to_s.rjust(2,'0'))
      expr_string += ("_and_" + node_string)
      j+=1
    end

    #creates 
    nil_array = []
    (20-(i-1)).times {nil_array << 'nil'}

    expr_string += "(#{path.join(',')+','+nil_array.join(',')})"
    puts expr_string
    eval(expr_string)

  end

  def find_related(args={},s=20, d=1, p=self.id)
    #this is used to return an array of related things, with relationship given by args[:group]
    #used by create_thing_path to generate the thing_path thing

    #args include [:group] (for user input) and node_list (for output)
    #p is the previous node, which has the relationship with the current
    #s is the number of steps left, d is the number of steps elapsed.  both need
    #to be local vars instead of args to allow them to change w context
    
    args[:node_list] ||= []
    args[:group] ||= ['thing_key_child','thing_key_parent']
    args[:group]=Array(args[:group])
    
    group_names = String.new
    #convert array to SQL args
    group_names = args[:group].collect {|g| "'#{g}',"}.to_s.chop
    
    #this ensures that the parent does not end up on both sides of the row
    sql_parent = "JOIN tag_values tv on tv.id = tg.tag_value_id
      AND tv.thing_id != #{p}"
    
    #find out the term ids of groups in the argument
    sql_thing_tag="SELECT DISTINCT tht.*
      FROM thing_tags tht
      JOIN tags tg ON tht.tag_id = tg.id   AND tht.active_flag = 1 
      #{sql_parent}
      #join to an thing of type group
      JOIN thing_tags gthtptht
      JOIN tags gthtptg ON gthtptg.id = gthtptht.tag_id
      JOIN tag_values gthtptv ON gthtptv.id = gthtptg.tag_value_id
      JOIN terms gthtptr ON gthtptr.id = gthtptv.term_id AND gthtptr.value = 'group'
      #whose name is supplied by the method argument
      JOIN thing_tags gthtn ON gthtn.thing_id = gthtptht.thing_id
      JOIN tags gtgn ON gtgn.id = gthtn.tag_id
      JOIN tag_values gtvn on gtvn.id = gtgn.tag_value_id
      JOIN terms gktrn ON gktrn.id = gtgn.key_term_id AND gktrn.value='name'
      JOIN terms gtvtrn ON gtvtrn.id = gtvn.term_id and gtvtrn.value IN (#{group_names})
      #and whose members are keys to tags on the target thing
      JOIN thing_tags gthtm ON gthtm.thing_id = gthtptht.thing_id
      JOIN tags gtgm ON gtgm.id = gthtm.tag_id
      JOIN tag_values gtvm on gtvm.id = gtgm.tag_value_id and gtvm.term_id = tg.key_term_id
      JOIN terms gktrm ON gktrm.id = gtgm.key_term_id AND gktrm.value='member'
      #and whose thing is the target thing
      WHERE tht.thing_id = #{self.id}"
    
    # find out thing_tags which contain the term ids of the argument groups
    @thing_tags  = ThingTag.find_by_sql(sql_thing_tag)

    #if no more steps, then simply return args[:node_list]
    if s != 0
      #decrement steps for next search level
      next_s = s-1
      next_d = d+1
      @thing_tags.each do |tht|
        # break the loop if the thing id in :until key is found
        args[:break]==true ? break : ''
        p = tht.thing.id
        v = tht.tag.tag_value.thing_id
        r = tht.tag.key
        args[:node_list].push({:p=>p,:r=>r,:v=>v,:d=>d})
        # if the thing id in :until key is found, set args[:break]= true for the recursive loop to break next time
        args[:until]==v ?  args[:break]= true : ''
        Thing.find(v).find_related(args,next_s,next_d,p)
      end
      return args[:node_list]
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
            @th=Thing.create
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

  def tag_list
    #used to return a simple list of tags for display in things_controller

    #attach name and thing_type
    @tag_list = [{:key=>'name',:value=>self.name},
      {:key=>'thing_type',:value=>self.thing_type.value}]

    self.tags.each do |tg|

      @tag_list << {:key=>tg.key,:value=>tg.value}

    end

    return @tag_list
  end

  def self.find_by_tags(args)
    #accepts hashes, with optional __ wildcards
    # finds only things that match all
    args = Array(args)

    keys[:child] = TermGroup.fbn('thing_key_child').members
    keys[:parent] = TermGroup.fbn('thing_key_parent').members

    args.each do |a|
      if a.class==Hash
        a.each { |k,v|
          va=Array(v)
          va.each do |v|
            if keys[:child].include?(k)
              
            elsif keys[:parent].include?(k)
              sql_join += "join things th#{i} on th#{i}.parent_id = th1.id "
              sql_join += "and th#{i}=#{v}" if v.tag_value_type=="number"
              i += 1
            elsif k=="name"
              
            elsif k=="thing_type"
              
            end
          end
        }
      elsif a.class==Symbol

      else

      end

    end
    

  end
  
  def add_tags(args)
    #args is a hash, with values that may be either single values or arrays of values
    keys = Hash.new

    keys[:child] = TermGroup.fbn('thing_key_child').members

    keys[:parent] = TermGroup.fbn('thing_key_parent').members

    args.each do |ksym,v|

      #store key and value for these tags;
      #convert key to string for use in database searches
      #convert value to array to allow all values to be treated as arrays,
      #since array is a permitted input. single inputs will be treated as 1-member arrays
      k = ksym.to_s
      va = Array(v)

      va.each do |v|
        if keys[:child].include?(k)
          # if the key term is a member of thing_key_child and child is marked as having a different
          # parent, delete that tag; then add self as new parent
          id.th.dt(k.to_sym) if self.parent_id && self.parent_id != v
          self.parent_id = v
          self.save!
        elsif keys[:parent].include?(k)
          # do the opposite for parent version
          self.dt(k.to_sym) if v.th.parent_id && v.th.parent_id != self.id
          @th_oth = v.th
          @th_oth.parent_id = self.id
          @th_oth.save!
        elsif k=="name" 
          self.dt(k.to_sym) if self.name && self.name != v
          self.name = v
          self.save!
        elsif k=="thing_type" 
          self.dt(k.to_sym) if self.thing_type && self.thing_type!=v
          self.thing_type_id = ThingType.find_or_create_by_value(v).id
          self.save!
        else
          #if key is neither parent, child, name, or thing_type, include it in the tags table

          #if key is address and thing_type is place, get geocoding info
          if k=="address" && self.thing_type && self.thing_type.value=='place'
  
            #replacing '&' with 'and' for geocoding purposes
            geo_rml=Geocoding.get( v.gsub('&',' and ') )
            
            #if latitude and longitude is found
            if geo_rml.length == 1
              self.at(:longitude=>geo_rml[0][8])
              self.at(:latitude=>geo_rml[0][9])
            end
          end

          #add simple text address to tags
          if v.tag_value_type=="term"
            Tag.find_or_create_by_thing_id_and_key_and_term(self.id,k,v)
          elsif v.tag_value_type=="blurb"
            Tag.find_or_create_by_thing_id_and_key_and_blurb(self.id,k,v)
          elsif v.tag_value_type=="date"
            Tag.find_or_create_by_thing_id_and_key_and_date(self.id,k,v)
          elsif v.tag_value_type=="number"
            Tag.find_or_create_by_thing_id_and_key_and_number(self.id,k,v)
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
      elsif k=="thing_type"
        args = {ksym => self.thing_type.value}
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
          end
        elsif keys[:parent].include?(k) 
          if v.th.parent_id == self.id
            @th_oth = v.th
            OldTag.find_or_create_by_thing_id_and_key_and_number_and_created_at(
              @th_oth.id,"parent_id",@th_oth.parent_id,self.created_at)
            @th_oth.parent_id = nil
            @th_oth.save!
          end
        elsif k=="name" 
          if self.name==v
            OldTag.find_or_create_by_thing_id_and_key_and_term_and_created_at(
              self.id,"name",self.name,self.created_at)
            self.name = nil
            self.save!
          end
        elsif k=="thing_type"
          if self.thing_type.value==v
            OldTag.find_or_create_by_thing_id_and_key_and_number_and_created_at(
              self.id,"thing_type_id",self.thing_type_id,self.created_at)
            self.thing_type_id = nil
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