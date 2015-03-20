class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      ## Database authenticatable
      t.string :email, default: ""
      t.string :encrypted_password, default: ""

      ## Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet :current_sign_in_ip
      t.inet :last_sign_in_ip

      # Custom attributes
      t.string :provider
      t.string :uid
      t.string :access_token
      t.string :image
      t.integer :total_follows
      t.integer :total_allowed_follows, default: 6000

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at


      # Uncomment below if timestamps were not included in your original model.
      t.timestamps
    end

    create_table :subjects do |t|
      t.belongs_to :user, index: true
      t.string :instagram_id

      t.integer :total_followers
      t.integer :follow_queue, array: true, default: []
      t.integer :unfollow_queue, array: true, default: []

      t.integer :followed_ids, array: true, default: []
      t.integer :unfollowed_ids, array: true, default: []
      t.integer :skipped_ids, array: true, default: []
      t.integer :next_cursor, default: 0, limit: 8

      # t.boolean :following, default: false
      # t.boolean :unfollowing, default: false
      t.boolean :finished, default: false
      t.boolean :busy, default: false

      t.timestamp :waiting, default: nil

      t.boolean :cancelled, default: false

      t.timestamps null: false
    end

    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end

  def self.down
    drop_table(:users)
  end
end
