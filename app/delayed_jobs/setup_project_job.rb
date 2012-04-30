class SetupProjectJob
  def initialize project_id
    @project_id = project_id
  end

  def perform
    project = Project.find(@project_id)
    project.initial_setup
  end
end

