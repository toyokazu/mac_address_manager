class AliasNamesController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter
  before_filter :authorize

  # GET /mac_addresses/1/alias_names
  # GET /mac_addresses/1/alias_names.xml
  def index
    begin
      @mac_address = MacAddress.find(params[:mac_address_id], gen_cond)
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end
    @alias_names = AliasName.all(:conditions => {:mac_address_id => @mac_address.id})

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @alias_names }
    end
  end

  # GET /mac_addresses/1/alias_names/1
  # GET /mac_addresses/1/alias_names/1.xml
  def show
    begin
      @mac_address = MacAddress.find(params[:mac_address_id], gen_cond)
      @alias_name = AliasName.find(params[:id], :conditions => {:mac_address_id => @mac_address.id})
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @alias_name }
    end
  end

  # GET /mac_addresses/1/alias_names/new
  # GET /mac_addresses/1/alias_names/new.xml
  def new
    begin
      @mac_address = MacAddress.find(params[:mac_address_id], gen_cond)
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end
    @alias_name = AliasName.new(:mac_address_id => @mac_address.id)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @alias_name }
    end
  end

  # GET /mac_addresses/1/alias_names/1/edit
  def edit
    begin
      @mac_address = MacAddress.find(params[:mac_address_id], gen_cond)
      @alias_name = AliasName.find(params[:id], :conditions => {:mac_address_id => @mac_address.id})
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end
  end

  # POST /mac_addresses/1/alias_names
  # POST /mac_addresses/1/alias_names.xml
  def create
    begin
      @mac_address = MacAddress.find(params[:mac_address_id], gen_cond)
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end
    @alias_name = AliasName.new(params[:alias_name].merge(:mac_address_id => @mac_address.id))

    respond_to do |format|
      if @alias_name.save
        flash[:notice] = 'AliasName was successfully created.'
        format.html { redirect_to(mac_address_alias_name_path(:id => @alias_name.id)) }
        format.xml  { render :xml => @alias_name, :status => :created, :location => @alias_name }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @alias_name.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /mac_addresses/1/alias_names/1
  # PUT /mac_addresses/1/alias_names/1.xml
  def update
    begin
      @mac_address = MacAddress.find(params[:mac_address_id], gen_cond)
      @alias_name = AliasName.find(params[:id], :conditions => {:mac_address_id => @mac_address.id})
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end

    respond_to do |format|
      if @alias_name.update_attributes(params[:alias_name].merge(:mac_address_id => @mac_address.id))
        flash[:notice] = 'AliasName was successfully updated.'
        format.html { redirect_to(mac_address_alias_name_path(:id => @alias_name.id)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @alias_name.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /mac_addresses/1/alias_names/1
  # DELETE /mac_addresses/1/alias_names/1.xml
  def destroy
    begin
      @mac_address = MacAddress.find(params[:mac_address_id], gen_cond)
      @alias_name = AliasName.find(params[:id], :conditions => {:mac_address_id => @mac_address.id})
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end
    @alias_name.destroy

    respond_to do |format|
      format.html { redirect_to(mac_address_alias_names_path(:mac_address_id => @mac_address.id)) }
      format.xml  { head :ok }
    end
  end

  def gen_cond
    return {} if admin_user?
    {:conditions => {:group_id => current_user.default_group.id}}
  end
end
