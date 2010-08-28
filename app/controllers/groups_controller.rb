class GroupsController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter
  before_filter :authorize
  # currently create and delete group are only operated by admin user.
  before_filter :check_admin, :only => [:new, :create, :destroy]

  # GET /groups
  # GET /groups.xml
  def index
    @groups = Group.all(:order => "display_name ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/1/edit
  def edit
    begin
      @group = Group.find(params[:id], gen_cond)
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to(@group) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    begin
      @group = Group.find(params[:id], gen_cond)
    rescue ActiveRecord::RecordNotFound => error
      flash[:notice] = 'You do not have a permission.'
      redirect_back_or_default and return
    end

    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(@group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    if @group.user.nil?
      @group.destroy
    else
      flash[:notice] = 'Group with user_id can not be removed.'
    end

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end

  def gen_cond
    return {} if admin_user?
    {:conditions => {:user_id => current_user.id}}
  end
end
