class UsersController < ApplicationController

  def login
    case request.method
      when :post
      if params[:user][:name].length>0 &&
          params[:user][:password_hash].length>0 &&
          session[:user] = User.authenticate(params[:user][:name], params[:user][:password_hash])
        flash[:notice]  = 'Login successful'
      else
        session[:user] = 1.u
        flash.now[:notice]  = 'Login unsuccessful'
        @login = params[:user][:name]
      end
    end
    redirect_to :controller=>'things',:action=>'retrieve'
  end

  def logout
    session[:user] = 1.u
    redirect_to :controller=>'things', :action=>'retrieve'
  end



end
