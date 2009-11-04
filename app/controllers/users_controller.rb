class UsersController < ApplicationController

  def login
    case request.method
      when :post
      if session[:user] = User.authenticate(params[:user][:name], params[:user][:password_hash])
        flash[:notice]  = 'Login successful'
      else
        session[:user] = 1.u
        flash.now[:notice]  = 'Login unsuccessful'
        @login = params[:user][:name]
      end
    end
    if request.xhr?
      render :update do |page|
      page.replace_html 'user_wrapper', :file=>'users/login'
      end
    end
  end

  def logout
    session[:user] = 1.u
    render :action=>'login'
  end



end
