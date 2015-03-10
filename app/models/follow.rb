class Follow < ActiveRecord::Base
  def self.where_finished
    where({finished: true}).all
  end

  def self.where_unfinished
    where({finished: false}).all
  end

  def self.by_uid(uid)
    where ({current_user_id: uid})
  end

  def follow_count
    self.follow_ids.count
  end

  def skipped_count
    self.skipped_ids.count
  end
end
