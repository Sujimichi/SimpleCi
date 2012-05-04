class ActionsController < ApplicationController
  include ActionView::Helpers::JavaScriptHelper

  def new
    @action = Action.new

    respond_to do |format|
      format.html {
        raise "formt.html"
        #return render :partial => "actions/fields", :locals => {:action => @action}, :layout => false
      } 
      format.js{
        #render :js => "$('#my_div').html('#{escape_javascript(render(:partial => 'actions/fields', :locals => {:action => @action}))}');"
        #$('testsearch').update("<%= escape_javascript(render :partial => 'homepage') %>");
        #return render :text => "<%= escape_javascript(fo) %>"
        return render :partial => "actions/fields", :locals => {:action => @action}, :layout => false
      }
    end
  end

  def create
    params[:action_data] = params[:actions].first.merge(params[:action_data]) if params[:actions]
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

  def update

    @action = Action.find(params[:id])
    @action.update_attributes(params[:action_data]) if params[:action_data]
    @action.active = !@action.active if params[:toggle_active]
    respond_to do |format|
      if @action.save
        format.html {  
          return render :partial => "actions/action", :locals => {:action => @action}
        }
        format.js {
          return render :partial => "actions/action", :locals => {:action => @action}
        }
      else
        format.html { render action: "edit" }
        format.js {
          return render :text => "failed", :status => 422
        }

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
