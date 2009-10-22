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
    @thing_types=ThingType.find(:all)
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

    #check to determine whether tag exists
    if @thing.tag_list.include?({:key=>@_params[:key], :value=>@_params[:value]}) then
      @thing.dt(@_params[:key].to_sym => @_params[:value])
      flash[:notice] = "deleted #{@_params[:key].to_sym} => #{@_params[:value]}"
    else
      flash[:notice] = "tag already deleted"
    end

    redirect_to(:action=>'show', :id=>@thing.id)

  end

  def destroy

    @thing = @_params[:id].to_i.th

    redirect_to(:action=>'show', :id=>@thing.id)
    
  end

  def add_thing

    #get thing
    @thing = @_params[:id].to_i.th

    Thing.find_or_create_by_name_and_parent_id_and_thing_type_id(
    @_params[:thing][:member_name],@thing.id,@_params[:thing][:member_thing_type_id])

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
      @thing = @_params[:id].to_i.th
      session[:context] = (@_params[:context] || session[:context] || 'members')
      session[:mode] = (@_params[:mode] || session[:mode] || 'show')
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
    @thing[:member_thing_type_id]=nil

    #get the members from the thing_path and add them to an array
    #this is used for the breadcrumbs / dropdown at the top of the page,
    @thing[:path] = @thing.parent_path << @thing.id
    
    #retrieve the names of the items in the path
    #so we can display the in the breadcrumbs / dropdown
    @thing[:path].collect!{|thn|
      {:id=>thn, :name=>thn.th.name}
    }

    if session[:context]=='members'

      #collect all the members, meaning things that have the parent_key =>value relationship
      #with the current Thing.
      #In the SF case, the members are neighborhoods in SF, such as tenderloin, soma, etc.
      #we retrieve both the name and the thing_type so we can tell places from items

      @thing[:member]=Thing.find_all_by_parent_id(@thing.id).collect do |th|
        { :id=>th.id,
          :name=>th.name,
          :thing_type=>th.thing_type.value
        }
      end

      #here we determine whether the user is searching or browsing, which is based on whether
      #a search argument was supplied in @_params above.  If they are searching, we get the
      #member_matches for the supplied thing, which are the members that contain the search term
      #if not, simply get every member and count the number of members beneath them to get the
      # thing count displayed in the front end

      @thing[:member].each do |m|
        if session[:search] then
          #parse out seatch terms
          #determine if current member is itself a match
          if @thing.create_member_match(:search=>session[:search]).fv(:member).collect do |thpm|
              thpm.th.fv(:target)[0].th.fv(:target)[0]
            end.include?(m[:id]) then m[:is_match]=true end
        else
          #collect children
          m[:member]=Thing.find_all_by_parent_id(m[:id]) do |th|
            {:id=>th.id}
          end
        end
      end
    
      #sort either by match score desc or by number of members desc, so that the best
      #matches OR the most populated places get sorted to the top
      @thing[:member]=@thing[:member].sort_by do |m|
        if session[:search] then
          chk = (m[:match].collect do |mm|
              mm[:match_score]
            end.join('+'))
          eval(chk) || 0.0
        else
          m[:member].length
        end
      end.reverse

    elsif session[:context]=='tag_list'

      #get the tags for the thing in question to display at the bottom
      @thing[:tag_list] = @thing.tag_list

    end

  end

end
