class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.string :source_path
      t.string :repo_path
      t.string :branch, :default => "master"
      t.string :setup_commands, :default => "bundle install\nbundle exec rake db:create:all\nbundle exec rake db:migrate\nbundle exec rake db:test:prepare"
      t.string :update_commands, :default => "bundle exec rake db:migrate\nbundle exec rake db:test:prepare"



      t.timestamps
    end
  end
end
