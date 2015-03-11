class CreateFollows < ActiveRecord::Migration
  def change
    create_table :follows do |t|
      t.string :chosen_user_id
      t.string :current_user_id
      t.text :status
      t.string :jid

      t.integer :total_followers
      t.integer :unfollow_count, default: 0
      t.integer :follow_ids, array: true, default: []
      t.integer :skipped_ids, array: true, default: []
      t.integer :next_cursor, default: 0, limit: 8

      t.boolean :finished, default: false
      t.boolean :following_done, default: false
      t.boolean :cancelled, default: false

      t.timestamps null: false
    end
  end
end
