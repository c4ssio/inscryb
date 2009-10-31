class ThingsController < ApplicationController

  def index
    #use 'members' context and 'show' mode by default
    session[:context] = 'members'
    #session[:mode] = 'show'
    #5 represents the ID for San Francisco
    #1 represents the ID for the inscryb root user
    session[:user_id]=1
    redirect_to(:action=>'show', :id=>5)
  end

  def search

    @all_matches = Thing.search(session[:search]).collect{|th| th.id}
    @member_matches = @thing.paths.select{|chpth|
      @all_matches.include?(chpth.target)}
    #length+2: +1 to get to actual thing's depth, +1 to get to member depth
    member_depth_str = (@thing.parent_nodes.length+2).to_s.rjust(2,'0')
    @thing.members.each do |m|
      m.matches=@member_matches.select{|mm|
        eval("mm.node#{member_depth_str}==#{m.id}")}.collect{|mm| mm.target.th }
      m.is_match=true if @member_matches.collect{|mm| mm.target}.include?(m.id)
    end

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

    if @thing.tags.collect{|tg| {:key=>tg.key,:value=>tg.value } }.include?(
        {:key=>@_params[:thing][:key], :value=>@_params[:thing][:value]}) then
      flash[:notice] = "tag already exists"
    else
      @thing.at(@_params[:thing][:key].to_sym => @_params[:thing][:value])
      flash[:notice] = "added #{@_params[:thing][:key].to_sym} => #{@_params[:thing][:value]}"
    end

    redirect_to(:action=>'show', :id=>@thing.id)

  end

  def clip_tag

    if ['cut','cpy'].include?(@_params[:op])
      op_id = Operation.find_or_create_by_name(@_params[:op]).id
      ClipboardMember.find_or_create_by_user_id_and_thing_id_and_operation_id(
        session[:user_id],@_params[:thing_id].to_i,op_id)
    end

    @_params[:clip_id].to_i.cm.delete if @_params[:op]=='cancel'

    if @_params[:op]=='paste'
      @cm = @_params[:clip_id].to_i.cm

      if @cm.operation.name == 'cut'
        if @_params[:tag_id]
          tag = @_params[:tag_id].to_i.tg
          @cm.thing_id.th.at(tag.key.to_sym => tag.value)
        else
          @cm.thing_id.th.at(:in => @_params[:id].to_i)
          @cm.delete
        end
      end
    end
    redirect_to(:action=>'show', :id=>@_params[:id].to_i)
  end

  def delete_tag

    @thing = @_params[:id].to_i.th
    thing_id = @_params[:thing_id]
    tag_id = @_params[:tag_id]

    #if there is a thing, then key is :has
    key = thing_id ? :has : tag_id.tg.key.to_sym
    value = tag_id==0 ? @thing.name : (thing_id.to_i || tag_id.to_i.tg.value)

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
    @new_thing = Thing.create
    @new_thing.at(:name=>@_params[:thing][:member_name])
    @new_thing.at(:in=>@thing.id)
    flash[:notice] = "added #{@_params[:thing][:member_name]} to #{@thing.name}"
    redirect_to(:action=>'show', :id=>@thing.id)

  end

  def retrieve

    identify

    #here we determine whether the user is searching or browsing, which is based on whether
    #a search argument was supplied in @_params above.  If they are searching, we get the
    #member_matches for the supplied thing, which are the members that contain the search term
    #if not, simply get every member and count the number of members beneath them to get the
    # thing count displayed in the front end
    search if session[:search]

    #sort by number of members desc, so that the most matches/members
    #get sorted to the top
    @thing.members=@thing.members.sort_by do |m|
      (session[:search] ? m.matches.length : m.members.length)
    end.reverse

    @clip_members = ClipboardMember.find_all_by_user_id(session[:user_id])
  end

  def identify
    #this action is designed to return data for a single model, in this case a single Thing.
    #For this, it needs the ID for the Thing in question.
    #the @_params variable: (the @ in front of it indicates it's an instance variable rather
    #than a local variable, which preserves it in memory for display after the method ends)
    #the @_params variable is supplied by the system when the user submits a request from the
    #front-end.  It includes variables submitted in forms, query strings in the URL, etc.

    if @_params[:thing]
      if @_params[:thing][:search]
      session[:search] = @_params[:thing][:search]
      session[:search]=nil if session[:search]==""
      end
      #user has defined thing by submitting form (such as from drop-down)
      @thing = (@_params[:thing][:id] || @_params[:id]).to_i.th
    else
      #user is coming to this from front-end or URl
      @thing = (@_params[:id].to_i !=0 ? @_params[:id].to_i : 5).th
    end
    #to populate search box
    @thing[:search]=session[:search]

    #TODO:remove this hack
    @thing[:key]=nil
    @thing[:value]=nil
    @thing[:member_name]=nil

    session[:mode] = (session[:search] ? 'show' : 'edit')


  end

  def show
    
    retrieve
    
  end

end
