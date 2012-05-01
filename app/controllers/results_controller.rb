class ResultsController < ApplicationController
  def index
    respond_to do |format|
      format.js {
        
        p = Project.find(params[:project_id])
        results = p.results
        if params[:last_result_id] && !params[:last_result_id].empty?
          lastest_results = results.select{|r| r.id > params[:last_result_id].to_i} 
          results = Result.where(:commit_id => lastest_results.map{|r| r.commit_id}, :project_id => params[:project_id])
        end
        render(:partial => "results/list", :locals => {:results => results, :project => p})
      }
    end
  end
end

