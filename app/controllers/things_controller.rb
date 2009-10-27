class ThingsController < ApplicationController

  def index
    #5 represents the ID for San Francisco
    redirect_to(:action=>'show', :id=>5)
  end

  def new
    
  end

  def edit
    session[:mode]='edit'
    redirect_to(:action=>'show', :id=>@_params[:id].to_i)
  end

  def add_tag
    #this action is used to attach new tags/members to a thing
    @thing = @_params[:id].to_i.th

    #check to determine whether tag already exists

    if @thing.tag_list.include?({:key=>@_params[:thing][:key], :value=>@_params[:thing][:value]}) then
      flash[:notice] = "tag already exists"
    else
      @thing.at(@_params[:thing][:key].to_sym => @_params[:thing][:value])
      flash[:notice] = "added #{@_params[:thing][:key].to_sym} => #{@_params[:thing][:value]}"
    end

    redirect_to(:action=>'show', :id=>@thing.id)

  end

  def delete_tag

    @thing = @_params[:id].to_i.th

    key = @_params[:key].to_sym

    #if we are deleting a member, value must be converted to integer
    value = (key==:has ? @_params[:value].to_i : @_params[:value])
    
    @thing.dt(key => value)
    
    redirect_to(:action=>'show', :id=>@thing.id)

  end

  def destroy

    @thing = @_params[:id].to_i.th

    redirect_to(:action=>'show', :id=>@thing.id)
    
  end

  def add_thing

    #get thing
    @thing = @_params[:id].to_i.th

    Thing.find_or_create_by_name_and_parent_id(
      @_params[:thing][:member_name],@thing.id)

    @thing.at(:has => @_params[:thing][:value])
    flash[:notice] = "added #{@_params[:thing][:member_name]} to #{@thing.name}"


    redirect_to(:action=>'show', :id=>@thing.id)

  end

  def show
    
    #the show action is designed to return data for a single model, in this case a single Thing.
    #For this, it needs the ID for the Thing in question.
    #the @_params variable: (the @ in front of it indicates it's an instance variable rather
    #than a local variable, which preserves it in memory for display after the method ends)
    #the @_params variable is supplied by the system when the user submits a request from the
    #front-end.  It includes variables submitted in forms, query strings in the URL, etc.

    if @_params
      #user is coming to this from front-end or URl
      @thing = (@_params[:id].to_i !=0 ? @_params[:id].to_i : 5).th
      session[:context] = (@_params[:context] || session[:context] || 'members')
      session[:mode] = (@_params[:mode] || session[:mode] || 'show')
      if @_params[:thing]
        if @_params[:thing][:search] == ""
          session[:search] = nil
        else
          session[:search] = @_params[:thing][:search]
        end
        #user has defined thing by submitting form (such as from drop-down)
        @thing = @_params[:thing][:id].to_i.th if @_params[:thing][:id]

      end
      #to populate search box
      @thing[:search]=session[:search]
    else
      #user is coming to this from root
      @thing = (@_params[:id].to_i != 0 ? @_params[:id].to_i.th : 5.th)
      #keeps errors from happening when rendering page
      session[:search] = nil
      #use 'members' context and 'show' mode by default
      session[:context] = 'members'
      session[:mode] = 'show'
    end

    #TODO:remove this hack
    @thing[:key]=nil
    @thing[:value]=nil
    @thing[:member_name]=nil

    #get the members from the thing_path and add them to an array
    #this is used for the breadcrumbs / dropdown at the top of the page,
    @thing[:path] = @thing.parent_path << @thing.id
    
    #retrieve the names of the items in the path
    #so we can display the in the breadcrumbs / dropdown
    @thing[:path].collect!{|thn|
      {:id=>thn, :name=>thn.th.name}
    }

      #collect all the members, meaning things that have the parent_key =>value relationship
      #with the current Thing.
      #In the SF case, the members are neighborhoods in SF, such as tenderloin, soma, etc.
      
      @thing[:member]=Thing.find_all_by_parent_id(@thing.id).collect do |th|
        { :id=>th.id,
          :name=>th.name
        }
      end

      #here we determine whether the user is searching or browsing, which is based on whether
      #a search argument was supplied in @_params above.  If they are searching, we get the
      #member_matches for the supplied thing, which are the members that contain the search term
      #if not, simply get every member and count the number of members beneath them to get the
      # thing count displayed in the front end

      if session[:search]
        @all_matches = Thing.search(session[:search]).collect{|th| th.id}
        @member_matches = @thing.paths.select{|chpth|
          @all_matches.include?(chpth.target)}
        #length+2: +1 to get to actual thing's depth, +1 to get to member depth
        member_depth_str = (@thing.parent_path.length+2).to_s.rjust(2,'0')
      end
      
      @thing[:member].each do |m|
        if session[:search] then
          m[:match]=@member_matches.select{|mm|
            eval("mm.node#{member_depth_str}==#{m[:id]}")}.collect{|mm| {:id=>mm.target} }
          m[:is_match]=true if @member_matches.collect{|mm| mm.target}.include?(m[:id])
        else
          #collect children
          m[:member]=Thing.find_all_by_parent_id(m[:id]) do |th|
            {:id=>th.id}
          end
        end
      end

      
      #sort by number of members desc, so that the most matches/members
      #get sorted to the top
      @thing[:member]=@thing[:member].sort_by do |m|
        (m[:member] ? m[:member].length : m[:match].length)
      end.reverse

    #get the tags for the thing in question to display at the bottom
    @thing[:tag_list] = @thing.tag_list

  end

end
