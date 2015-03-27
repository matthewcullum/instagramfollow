class InstagramService

  TOO_MANY_REQUESTS = 0
  USER_FOLLOW_LIMIT_EXCEEDED = 1
  UNFOLLOWS_QUEUED = 3
  FINISHED_UNFOLLOWING = 4
  FINISHED_FOLLOWING = 5
  FOLLOW_CANCELLED = 6


  def initialize(current_user_id, *args)
    options = args.extract_options!
    @current_user = User.find current_user_id
    @current_user.total_allowed_follows = 6000
    @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: @current_user.access_token
    # opt_total_follow_count = options[:total_follow_count]
    # @total_follow_count = opt_total_follow_count.empty? options[:total_follow_count] : @user_profile[:counts][:follow]

    # @local_env = Rails.env.test? || Rails.env.development?
    @local_env = false
    @test_env = Rails.env.test?
    @counts = 0
  end

  # helpers
  def exceeded_follow_limit?
    user_profile = @client.user @current_user.uid
    total_follow_count = user_profile[:counts][:follows] + @counts
    total_follow_count >= @current_user.total_allowed_follows
  end

  def start_follow_routine

    subject = @current_user.subjects.next_in_follow_queue
    if subject and not @current_user.subjects.any_busy?
      puts "starting unfollow routine for #{subject}"

      subject.busy = true
      subject.waiting = false
      subject.save

      status = follow_all_in_queue(subject)

      case status
        when TOO_MANY_REQUESTS
          puts 'too many requests'
          delay = 1.hour
          subject.busy = false
          subject.waiting = delay.from_now
          subject.save
          puts "queueing followjob in #{delay / 60} minutes"
          FollowJob.perform_in delay, @current_user.id
        when USER_FOLLOW_LIMIT_EXCEEDED
          puts 'follow limit exceeded'
          buffer = 1000

          unfollow_ids = subject.followed_ids.pop(buffer)
          unfollow_ids += subject.skipped_ids.pop(buffer - unfollow_ids.count)

          subject.unfollow_queue = unfollow_ids
          subject.busy = false
          subject.save

          UnfollowJob.perform_async @current_user.id

        when FINISHED_FOLLOWING
          subject.busy = false

          puts 'finished following'

          new_subject = @current_user.subjects.next_in_follow_queue
          if new_subject
            subject.save
            puts 'queueing follow job'
            FollowJob.perform_async @current_user.id
          else

            subject.save
          end
        when FOLLOW_CANCELLED
          subject.unfollow_queue = subject.followed_ids + subject.skipped_ids
          subject.unfollow_queue = []
          subject.followed_ids = []
          subject.skipped_ids = []
          subject.busy = false
          subject.save
      end
    end
  end

  def follow_all_in_queue(subject)

    # don't follow if unfollows are queued
    return UNFOLLOWS_QUEUED unless subject.unfollow_queue.empty?

    # add follows to queue if already empty
    subject.follow_queue = get_all_follower_ids(subject) if subject.follow_queue.empty?
    subject.save

    unknown_error_count = 0
    unknown_error_tolerance = 5

    loop do

      if exceeded_follow_limit?
        return USER_FOLLOW_LIMIT_EXCEEDED

      elsif subject.reload.cancelled
        return FOLLOW_CANCELLED

      else
        follower_id = subject.follow_queue.pop

        if follower_id # if the follower_id is truthy, we can follow it

          begin
            unless @local_env
              @client.follow_user follower_id
            end
            subject.followed_ids << follower_id
            @counts += 1

          rescue Instagram::TooManyRequests
            subject.follow_queue << follower_id
            subject.save
            return TOO_MANY_REQUESTS
          rescue Instagram::Error
            subject.skipped_ids << follower_id
          rescue
            subject.follow_queue << follower_id
            if unknown_error_count >= unknown_error_tolerance
              subject.save
              raise $!
            else
              @unknown_error_count += 1
            end
          ensure
            subject.save
          end

        else # else we can assume that we've followed everyone in the queue
          subject.unfollow_queue = subject.followed_ids + subject.skipped_ids
          subject.followed_ids = []
          subject.save
          return FINISHED_FOLLOWING
        end
      end
    end
  end

  def start_unfollow_routine
    subject = @current_user.subjects.next_in_unfollow_queue
    if subject and not @current_user.subjects.any_busy?
      puts "starting unfollow routine for #{subject}"
      subject.busy = true
      subject.waiting = false
      subject.save
      status = unfollow_all_in_queue subject

      case status
        when TOO_MANY_REQUESTS
          puts 'too many follow requests'
          delay = 1.hour
          subject.busy = false
          subject.waiting = delay.from_now
          subject.save
          puts "queueing unfollow in #{delay/60} minutes"
          UnfollowJob.perform_in delay, @current_user.id
        when FINISHED_UNFOLLOWING
          puts 'finished unfollowing'
          subject_finished = subject.follow_queue.empty?
          subject.busy = false
          subject.finished = subject_finished

          subjects = @current_user.subjects

          if subjects.next_in_unfollow_queue
            subject.save
            puts 'queueing unfollowjob'
            UnfollowJob.perform_async @current_user.id
          elsif subjects.next_in_follow_queue or not subject_finished
            subject.save
            puts 'queuing follow job'
            FollowJob.perform_async @current_user.id
          else
            subject.save
          end
        when FOLLOW_CANCELLED
          subject.unfollow_queue = subject.followed_ids + subject.skipped_ids
          subject.follow_queue = []
          subject.save
      end
    end
  end

  def unfollow_all_in_queue(subject)

    unfollow_queue = subject.unfollow_queue

    loop do
      unfollow_id = unfollow_queue.pop

      if not unfollow_id
        return FINISHED_UNFOLLOWING
      else
        begin
          @client.unfollow_user unfollow_id unless @local_env

          subject.unfollowed_ids << unfollow_id
          subject.save
        rescue Instagram::TooManyRequests
          return TOO_MANY_REQUESTS
        end
      end
    end
  end

  def get_all_follower_ids(subject)
    follower_ids = []
    next_cursor = nil

    loop do
      followed_by = @client.user_followed_by subject.instagram_id, cursor: next_cursor
      next_cursor = followed_by.pagination.next_cursor
      followed_by.each { |follower| follower_ids << follower.id.to_i }

      break if next_cursor.nil?
    end
    follower_ids
  end

end