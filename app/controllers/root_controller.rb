class RootController < ApplicationController
  before_filter CASClient::Frameworks::Rails::GatewayFilter, :only => :index
  before_filter CASClient::Frameworks::Rails::Filter, :except => :index

  def index
  end

  def logout
    @admin_user = nil
    @current_user = nil
    CASClient::Frameworks::Rails::Filter.logout(self, request.referer) and return
  end

end
