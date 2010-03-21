class RootController < ApplicationController
  before_filter CASClient::Frameworks::Rails::GatewayFilter, :only => :index
  before_filter CASClient::Frameworks::Rails::Filter, :except => :index

  def index
  end

  def logout
    CASClient::Frameworks::Rails::Filter.logout(self, request.referer) and return
  end

end
