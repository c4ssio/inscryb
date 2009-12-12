# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency 'password'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  #disabled protext from forgery to allow xml based posts without needing to reload the page
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end
