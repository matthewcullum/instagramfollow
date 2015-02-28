class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|

      t.string :uid
      t.integer :current_index
      t.integer :total_followed

      t.timestamps null: false
    end
  end
end
