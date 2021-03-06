class ProjectsController < ApplicationController

  def index
    @projects = Project.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  def show
    @project = Project.find(params[:id])
    respond_to do |format|
      format.html {} 
      format.json {
        if params[:get_status]


          updating = Rails.cache.fetch("project_#{@project.id}_updating") if Rails.cache.fetch("project_#{@project.id}_updating")
          initializing = Rails.cache.fetch("project_#{@project.id}_initializing") if Rails.cache.fetch("project_#{@project.id}_initializing")

          count = @project.actions.map{|a|  Rails.cache.fetch("action_#{a.id}:started").blank? ? 0 : 1 }.sum

          data = {:job_count => count}
          data.merge!(:initializing => initializing) if initializing
          data.merge!(:updating => updating) if updating


          return render :json => data.to_json #{:count => count, :info => info}.to_json
        end
      }
    end
  end

  def new
    @project = Project.new
    @project.actions.build
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
    @project = Project.find(params[:id])
  end

  def create
    @project = Project.new(params[:project])

    params[:actions].each do |action|
      action = @project.actions.new(action.merge(:project => @project, :active => true))
    end

    respond_to do |format|
      if @project.save
        @project.actions.each{|a| a.save if a.valid?}
        
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  def update
    @project = Project.find(params[:id])

    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :no_content }
    end
  end
end
