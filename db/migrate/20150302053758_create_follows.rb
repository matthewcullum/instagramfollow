class CreateFollows < ActiveRecord::Migration
  def change
    create_table :follows do |t|
      t.string :chosen_user_id
      t.string :current_user_id
      t.integer :total_followers
      t.integer :follow_count, default: 0
      t.integer :unfollow_count, default: 0
      t.string :status
      t.integer :follow_ids, array: true, default: []
      t.boolean :cancelled, default: false

      t.timestamps null: false
    end
  end
end
