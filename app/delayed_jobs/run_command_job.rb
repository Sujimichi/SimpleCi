class RunCommandJob
  def initialize action_id
    @action_id = action_id
  end

  def perform
    action = Action.find(@action_id)
    action.run_command
  end
end

