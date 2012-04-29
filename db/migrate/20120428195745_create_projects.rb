class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.string :source_path
      t.string :repo_path
      t.string :branch

      t.timestamps
    end
  end
end
