class ResultsController < ApplicationController
  def index
    respond_to do |format|
      format.js {
        p = Project.find(params[:project_id]) if params[:project_id]
        results = p.nil? ? Result.all : p.results
        render(:partial => "results/list", :locals => {:results => results})
      }
    end
  end
end

