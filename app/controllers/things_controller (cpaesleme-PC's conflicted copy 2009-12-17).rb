class ThingsController < ApplicationController

  def index
    search
    refresh
  end

  def search
    identify

    session[:search] = (self.params[:search] || session[:search])
    session[:search] = nil if session[:search].to_s.strip==""

    #populates thing and its parent with the matches
    @thing.get_child_matches(session[:search])
    @parent_thing.get_child_matches(session[:search]) if @parent_thing
    child_matches = (@parent_thing || @thing).child_matches
    #store parent paths for nodes in this
    parent_paths = Array.new
    #generate xml
    @xml_paths = Builder::XmlMarkup.new;nil
    @xml_tags = Builder::XmlMarkup.new;nil
    @xml_paths.paths do
      child_matches.each do |chm|
        @xml_paths.path do
          chm_target_th=chm.target.th
          @xml_paths.target{
            @xml_paths.thing_id(chm_target_th.id)
            @xml_paths.name(chm_target_th.name)
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
        (child_matches + parent_paths).each do |p|
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
    if request.xhr?
      #user is updating the screen with results of latest search
      refresh
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
    #this action is responsible for updating the xml on the page
    #with the dataset returned by the search action

    #xml builders
    #sort by number of members desc, so that the most matches/members
    #get sorted to the top
    @thing.children=@thing.children.sort_by do |m|
      (session[:search] ? m.child_matches.length : m.children.length)
    end.reverse
    
    if request.xhr?
      render :update do |page|
        #these pieces change the display on the screen, which is the default;
        #however, user has option of updating only the xml
        unless (self.params[:display] && self.params[:display]=='false')
          page.replace_html 'child_and_tag_wrapper', :file=>'things/refresh'
          page.replace_html 'clip_member_wrapper', :partial=>'clip_members'
          page.replace_html 'thing_header_wrapper', :partial=>'thing_header'
          page.replace_html 'add_tag_wrapper', :partial=>'add_tag'
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
        page.replace_html 'xml_wrapper', :partial=>'xml'
        #hide edit elements unless user is authenticated and not searching`
      end
    end
    
  end

  def identify
    #this action identifies the thing the user is currently viewing
    #and stores it as a session variable

    session[:user]||=1.u

    session[:id] = (self.params[:id] || session[:id] || 5).to_i

    @thing = session[:id].th

    @thing[:search]=session[:search]

    #set parent
    @parent_thing = @thing.parent if @thing.parent

    @xml_context = Builder::XmlMarkup.new;nil
    @xml_context.context do
      @xml_context.thing_id(session[:id])
      @xml_context.search(session[:search])
      @xml_context.user_id(session[:user].id)
      #mark top node
      @xml_context.top_node_thing_id((@parent_thing || @thing).id)
    end

    #this identifies a simple polling request from user's navigation
    render :nothing=>true if action_name == 'identify'

  end
end