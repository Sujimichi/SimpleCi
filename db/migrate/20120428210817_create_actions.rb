class CreateActions < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.integer :project_id
      t.string :command
      t.string :result_matcher

      t.timestamps
    end
  end
end
