class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.integer :project_id
      t.integer :action_id
      t.string :commit_id
      t.text :data

      t.timestamps
    end
  end
end
