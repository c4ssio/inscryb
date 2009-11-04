class ThingsController < ApplicationController

  def index
    
    identify unless @thing

    redirect_to(:action=>'show', :id=>@thing.id)
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

  def rename_thing
    @_params[:id].to_i.th.at(:name=>@_params[:name])
    render :nothing
  end

  def add_tag
    #this action is used to attach new tags/members to a thing
    identify unless @thing

    #check to determine whether tag already exists

    if @thing.tags.collect{|tg| {:key=>tg.key,:value=>tg.value } }.include?(
        {:key=>@_params[:thing][:key], :value=>@_params[:thing][:value]}) then
      flash[:notice] = "tag already exists"
    else
      @thing.at(@_params[:thing][:key].to_sym => @_params[:thing][:value], :creator_id=>session[:user].id)
      flash[:notice] = "added #{@_params[:thing][:key].to_sym} => #{@_params[:thing][:value]}"
    end

    retrieve

  end

  def clip_tag

    identify unless @thing

    if @_params[:op]=='cut'
      op_id = Operation.find_or_create_by_name(@_params[:op]).id
      ClipboardMember.find_or_create_by_user_id_and_thing_id_and_operation_id(
        session[:user].id,@_params[:thing_id].to_i,op_id)
      #this ensures that only the clip renders
    end

    @_params[:clip_id].to_i.cm.delete if @_params[:op]=='cancel'

    @clip_only=true if ['cut','cancel'].include?(@_params[:op])

    if @_params[:op]=='paste'
      @cm = @_params[:clip_id].to_i.cm
      @cm.thing_id.th.at(:in => @_params[:id].to_i, :creator_id=>session[:user].id)
      @cm.delete
      @_params[:op]=nil
    end

    retrieve
    
  end

  def delete_tag

    identify unless @thing
    thing_id = @_params[:thing_id]
    tag_id = @_params[:tag_id]

    #if there is a thing, then key is :has
    key = thing_id ? :has : tag_id.to_i.tg.key.to_sym
    value = thing_id ? thing_id.to_i : tag_id.to_i.tg.value

    @thing.dt(key => value)

    if thing_id
      ClipboardMember.find_all_by_thing_id(thing_id).each {|cm| cm.delete}
    end
  
    retrieve

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

    @clip_members ||= ClipboardMember.find_all_by_user_id(session[:user].id)

    if request.xhr?
      render :update do |page|
        page.replace_html 'member_and_tag_wrapper', :file=>'things/retrieve'
        page.replace_html 'clip_member_wrapper', :partial=>'clip_members'
        page.replace_html 'path_wrapper', :partial=>'path'
        session[:search] ? page.show('clear_search_button') : page.hide('clear_search_button')
      end
    end
    
  end

  def identify
    #this action is designed to return data for a single model, in this case a single Thing.
    #For this, it needs the ID for the Thing in question.
    #the @_params variable: (the @ in front of it indicates it's an instance variable rather
    #than a local variable, which preserves it in memory for display after the method ends)
    #the @_params variable is supplied by the system when the user submits a request from the
    #front-end.  It includes variables submitted in forms, query strings in the URL, etc.

    #5 represents the ID for San Francisco
    #1 represents the ID for the inscryb root user
    session[:user]||=1.u

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

    #set default values
    @thing[:key]||='has'
    @thing[:value]=nil

  end

  def show
    retrieve
  end

end
