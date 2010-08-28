require 'csv'
require 'ipaddr'
class MacAddressesController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter
  before_filter :authorize

  # GET /mac_addresses
  # GET /mac_addresses.xml
  # for admin_user
  # GET /groups/1/mac_addresses
  # GET /groups/1/mac_addresses.xml
  def index
    if !params["group_id"].nil? && admin_user?
      begin
        @group = Group.find(params["group_id"])
      rescue ActiveRecord::RecordNotFound => error
        flash[:notice] = 'Specified group does not exists.'
        redirect_back_or_default and return
      end
    end
    @mac_addresses = MacAddress.all(gen_cond(params["group_id"]))
    @mac_addresses = @mac_addresses.sort {|a, b| IPAddr.new(a.ipv4_addr.empty? ? "255.255.255.255" : a.ipv4_addr) <=> IPAddr.new(b.ipv4_addr.empty? ? "255.255.255.255" : b.ipv4_addr)}

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mac_addresses }
      format.csv do
        CSV::Writer.generate(output = "", "\t") do |csv|
          @mac_addresses.each do |mac_addr|
            csv << [mac_addr.hostname, mac_addr.mac_addr, mac_addr.description]
          end
        end
        send_data(output, :type => 'text/csv')
      end
    end
  end

  # GET /mac_addresses/1
  # GET /mac_addresses/1.xml
  # for admin_user
  # GET /groups/1/mac_addresses
  # GET /groups/1/mac_addresses.xml
  def show
    if !params["group_id"].nil? && admin_user?
      begin
        @group = Group.find(params["group_id"])
      rescue ActiveRecord::RecordNotFound => error
        flash[:notice] = 'Specified group does not exists.'
        redirect_back_or_default and return
      end
    end
    begin
      @mac_address = MacAddress.find(params[:id], gen_cond(params["group_id"]))
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @mac_address }
    end
  end

  # GET /mac_addresses/new
  # GET /mac_addresses/new.xml
  def new
    @mac_address = MacAddress.new(:group_id => current_user.default_group_id)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mac_address }
    end
  end

  # GET /mac_addresses/upload
  def upload
    respond_to do |format|
      format.html # upload.html.erb
    end
  end

  # GET /mac_addresses/1/edit
  def edit
    begin
      @mac_address = MacAddress.find(params[:id], gen_cond)
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end
  end

  # POST /mac_addresses
  # POST /mac_addresses.xml
  def create
    @mac_address = MacAddress.new(params[:mac_address])

    respond_to do |format|
      if @mac_address.save
        flash[:notice] = 'MacAddress was successfully created.'
        format.html { redirect_to(@mac_address) }
        format.xml  { render :xml => @mac_address, :status => :created, :location => @mac_address }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @mac_address.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /mac_addresses/update_all
  def update_all
    client = Rinda::Client.new('update', :key => session[:session_id])
    repeat_count = 3
    until client.worker.lock(current_user.default_group.id)
      sleep(1)
      repeat_count = repeat_count - 1
      if repeat_count == 0
        flash[:notice] = 'Update daemon seems to be busy now. Please wait a few minutes and try again.'
        redirect_back_or_default and return
      end
    end
    client.update_and_unlock_request(current_user.default_group.id, params[:file][:csv])

    respond_to do |format|
      format.html { redirect_to(root_path) }
      format.xml  { render :xml => :ok }
    end
  end

  # PUT /mac_addresses/1
  # PUT /mac_addresses/1.xml
  def update
    begin
      @mac_address = MacAddress.find(params[:id], gen_cond)
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end

    respond_to do |format|
      if @mac_address.update_attributes(params[:mac_address])
        flash[:notice] = 'MacAddress was successfully updated.'
        format.html { redirect_to(@mac_address) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mac_address.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /mac_addresses/1
  # DELETE /mac_addresses/1.xml
  def destroy
    begin
      @mac_address = MacAddress.find(params[:id], gen_cond)
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end
    @mac_address.destroy

    respond_to do |format|
      format.html { redirect_to(mac_addresses_url) }
      format.xml  { head :ok }
    end
  end

  def gen_cond(group_id = nil)
    if admin_user?
      return {} if group_id.nil?
      return {:conditions => {:group_id => group_id}}
    end
    {:conditions => {:group_id => current_user.default_group.id}}
  end
end
