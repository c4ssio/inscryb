class ThingsController < ApplicationController

  def index
    refresh
  end

  def search
    #populates thing and its parent with the matches
    @thing.get_child_matches(session[:search])
    @parent_thing.get_child_matches(session[:search]) if @parent_thing
    child_matches = (@parent_thing || @thing).child_matches
    #store parent paths for nodes in this
    parent_paths = Array.new
    #generate xml
    @xml_paths.paths do
      child_matches.each do |chm|
        @xml_paths.path do
          chm_target_th=chm.target.th
          @xml_paths.target{
            @xml_paths.thing_id(chm_target_th.id)
            @xml_paths.name(chm_target_th.name)
            #used for collecting children under parent
            @xml_paths.parent_thing_id(chm_target_th.parent.id)
          }
          (1..20).each do |n|
            chm_node_th = (chm.node(n) ? chm.node(n).th : nil )
            break unless chm_node_th
            #add node to list of parent paths
            chm_node_pth = chm_node_th.id.pth
            parent_paths << chm_node_pth unless (parent_paths.include?(chm_node_pth) || child_matches.include?(chm_node_pth) || chm_node_pth.nil?)
            @xml_paths.tag!("node"+n.to_s.rjust(2,'0')){
              @xml_paths.thing_id(chm_node_th.id)
            }
          end
        end
      end
      #add parent_paths with non-match tag
      parent_paths.each do |pp|
        @xml_paths.path do
          pp_target_th=pp.target.th
          @xml_paths.target{
            @xml_paths.thing_id(pp_target_th.id)
            @xml_paths.name(pp_target_th.name)
            @xml_paths.nonmatch('true')
          }
          (1..20).each do |n|
            pp_node_th = (pp.node(n) ? pp.node(n).th : nil )
            break unless pp_node_th
            @xml_paths.tag!("node"+n.to_s.rjust(2,'0')){
              @xml_paths.thing_id(pp_node_th.id)
            }
          end
        end
      end
      #add tags for all paths
      @xml_tags.things do
        (child_paths + parent_paths).each do |p|
          @xml_tags.thing do
            @xml_tags.thing_id(p.target)
            @xml_tags.tags do
              p.target.th.tags do |tg|
                @xml_tags.tag do
                  @xml_tags.key(tg.key)
                  @xml_tags.value(tg.value)
                end
              end
            end
          end
        end
      end
    end
  end

  def browse
    #generate xml
    @xml_paths.paths do
      (@parent_thing || @thing).paths.each do |p|
        @xml_paths.path do
          p_target_th=p.target.th
          @xml_paths.target{
            @xml_paths.thing_id(p_target_th.id)
            @xml_paths.name(p_target_th.name)
          }
          (1..20).each do |n|
            p_node_th = (p.node(n) ? p.node(n).th : nil )
            break unless p_node_th
            @xml_paths.tag!("node"+n.to_s.rjust(2,'0')){
              @xml_paths.thing_id(p_node_th.id)
            }
          end
        end
      end
    end
    #add tags
    @xml_tags.things do
      (@parent_thing || @thing).paths.each do |p|
        @xml_tags.thing do
          @xml_tags.thing_id(p.target)
          @xml_tags.tags do
            p.target.th.tags.each do |tg|
              @xml_tags.tag do
                @xml_tags.key(tg.key)
                @xml_tags.value(tg.value)
              end
            end
          end
        end
      end
    end
  end

  def add_tag
    #check to determine whether tag already exists
    if @thing.tags.collect{|tg| {:key=>tg.key,:value=>tg.value } }.include?(
        {:key=>@_params[:key], :value=>@_params[:value]}) then
    else
      #if user enters type
      if @_params[:key] == 'type'
        @thing.add_type_by_user(@_params[:value],session[:user].id)
      else
        @thing.at(@_params[:key].to_sym => @_params[:value], :creator_id=>session[:user].id)
      end
    end
    render :nothing
  end

  def clip
    op_id = Operation.find_or_create_by_name('cut').id
    @cm = ClipboardMember.find_or_create_by_user_id_and_thing_id_and_operation_id(
      session[:user].id,@_params[:thing_id].to_i,op_id)
    @cm.delete if @_params[:op]=='cancel'
    if @_params[:op]=='paste'
      @cm.thing_id.th.at(:in => @_params[:id].to_i, :creator_id=>session[:user].id)
      @cm.delete
      @_params[:op]=nil
    end
    render :nothing
  end

  def delete_tag
    thing_id = @_params[:thing_id]
    tag_id = @_params[:tag_id]

    #if there is a thing, then key is :has
    key = thing_id ? :has : tag_id.to_i.tg.key.to_sym
    value = thing_id ? thing_id.to_i : tag_id.to_i.tg.value

    @thing.dt(key => value,:creator_id=>session[:user].id)

    if thing_id
      ClipboardMember.find_all_by_thing_id(thing_id).each {|cm| cm.delete}
    end
    render :nothing
  end

  def refresh

    identify
    
    #here we determine whether the user is searching or browsing, which is based on whether
    #a search argument was supplied in @_params above.  If they are searching, we get the
    #child_matches for the supplied thing, which are the members that contain the search term
    #if not, simply get every child and count the number of members beneath them to get the
    # thing count displayed in the front end
    session[:search] ? search : browse

    #sort by number of members desc, so that the most matches/members
    #get sorted to the top
    @thing.children=@thing.children.sort_by do |m|
      (session[:search] ? m.child_matches.length : m.children.length)
    end.reverse

    @clip_members ||= ClipboardMember.find_all_by_user_id(session[:user].id)

    @hide_edits = (session[:search] || session[:user].id==1)
    
    if request.xhr?
      render :update do |page|
        page.replace_html 'child_and_tag_wrapper', :file=>'things/refresh'
        page.replace_html 'clip_member_wrapper', :partial=>'clip_members'
        page.replace_html 'thing_header_wrapper', :partial=>'thing_header'
        page.replace_html 'add_tag_wrapper', :partial=>'add_tag'
        page.replace_html 'data_island_wrapper', :partial=>'xml'
        #hide edit elements unless user is authenticated and not searching
        if @hide_edits
          page.hide('add_tag_wrapper')
          page.hide('clip_member_wrapper')
          page[:thing_search].focus
        else
          page.show('add_tag_wrapper')
          page.show('clip_member_wrapper')
          page[:thing_tag_value].focus
        end
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

    unless @thing

      if @_params[:search]
        session[:search] = @_params[:search]
        session[:search]=nil if session[:search].to_s.strip==""
      end

      if @_params[:thing]
        #user has defined thing by submitting form (such as from drop-down)
        @thing = (@_params[:thing][:id] || @_params[:id]).to_i.th
        @thing.key=@_params[:thing][:key]
        @thing.value=@_params[:thing][:value]
      else
        #user is coming to this from front-end or URl
        @thing = (@_params[:id].to_i !=0 ? @_params[:id].to_i : 5).th
      end
      #to populate search box
      @thing[:search]=session[:search]

      #set default values
      @thing.key||='has'
      @thing.value||=nil

    end

    #set parent
    @parent_thing = @thing.parent if @thing.parent

    #XML Builders; need to put in nil to avoid inspect autotag
    @xml_context = Builder::XmlMarkup.new;nil
    @xml_paths = Builder::XmlMarkup.new;nil
    @xml_tags = Builder::XmlMarkup.new;nil
    @xml_clipboard = Builder::XmlMarkup.new;nil

    @xml_context.context do
      @xml_context.thing_id(@thing.id)
      @xml_context.search(@thing[:search])
      @xml_context.user_id(session[:user].id)
    end
  end

  def show
    refresh
  end

end
