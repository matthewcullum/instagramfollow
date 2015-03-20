class Subject < ActiveRecord::Base
  belongs_to :user

  def self.pending
    where(busy: false, finished: false)
  end

  def self.pending_count
    pending.count
  end

  def self.any_pending?
    pending_count > 0
  end

  def self.unfinished
    where finished: false
  end

  def self.finished
    where finished: true
  end

  def self.busy
    where(busy: true)
  end

  def self.any_busy?
    busy = where busy: true
    busy.count > 0
  end

  def self.next_in_follow_queue
    results = pending.select { |subject| subject.unfollow_queue.empty? }
    results.first
  end

  def self.next_in_unfollow_queue
    results = pending.select { |subject| !subject.unfollow_queue.empty? }
    results.last
  end

  def followed_count
    followed_ids.count + unfollow_queue.count
  end

  def unfollowed_count
    unfollowed_ids.count
  end

  def skipped_count
    skipped_ids.count
  end

  def finished?

  end

  def pending_unfollow
    if user.exceeded_follow_limit?
      where("following_done = false")
    else
      where("following_done = true or cancelled = true")
    end
  end


end
