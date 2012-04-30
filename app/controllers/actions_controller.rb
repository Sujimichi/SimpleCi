class ActionsController < ApplicationController
  
  def new
    @action = Action.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @action = Action.new(params[:action_data]) #slight issue with the name action.  the action key get overwritten by :action => create, doh!.  used :as => "action_data" in the form_for helper

    respond_to do |format|
      if @action.save
        format.html { 
          redirect_to :back, notice: 'Action was added' 
        }
      else
        format.html { render action: "new" }
      end
    end
  end

  def destroy
    @action = Action.find(params[:id])
    @action.destroy
    respond_to do |format|
      format.html { redirect_to :back }
    end
  end
end
