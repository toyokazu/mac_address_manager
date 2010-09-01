# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def authorized?
    @current_user ||= User.first(:conditions => {:name => session[:cas_user]})
    !@current_user.nil?
  end

  def admin_user?
    @admin_user ||= @current_user.roles.any? {|role| role.name == 'admin'}
  end

  def current_user
    @current_user
  end

  def redirect_back_or_default
    redirect_to(request.referer || root_path)
  end

  def authorize
    if !authorized?
      flash[:notice] = "You are not authorized to view this page."
      redirect_back_or_default and return
    end
  end

  def check_admin
    if !admin_user?
      flash[:notice] = "This page requires admin role."
      redirect_back_or_default and return
    end
  end

  # TupleSpace druby URI.
  # If you use RingServer, you should specify nil.
  def ts_uri
    "druby://localhost:54321"
  end
end
