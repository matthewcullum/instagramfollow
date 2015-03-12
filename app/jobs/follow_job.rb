class FollowJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(follow_id, *args)

    options = args.extract_options!

    @follow = Follow.find follow_id
    puts "Follow: #{@follow.inspect}"
    @current_user_local = User.find_by_uid @follow.current_user_id

    @access_token = @current_user_local.oauth_token
    @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: @access_token

    @current_user = @client.user @follow.current_user_id
    @chosen_user = @client.user(@follow.chosen_user_id)
    @total_allowed_follows = @current_user_local.total_allowed_follows
    @next_cursor = @follow.next_cursor
    @current_follow_set = nil
    @debug_mode = true

    if @debug_mode
      @temp_limit = @current_user[:counts][:follows] += 10
    end

    def save_follow
      @follow.save
    end

    def cancelled?
      @follow.reload
      @follow.cancelled
    end

    def followed_everyone?
      follow_count = @follow.follow_count
      total_followers = @follow.total_followers

      follow_count >= total_followers
    end

    def already_followed?(follower_id)
      follow_ids = @follow.follow_ids
      skipped_ids = @follow.skipped_ids

      follow_ids.include? follower_id or skipped_ids.include? follower_id
    end


    def user_exceeded_follow_limit?
      user_total_follows = @client.user(@follow.current_user_id)[:counts][:follows]
      user_total_follows >= @total_allowed_follows
    end

    def next_follow_set

      @current_cursor = @follow.next_cursor

      follow_set = @client.user_followed_by @chosen_user.id, cursor: @next_cursor
      @next_cursor = follow_set.pagination.next_cursor
      @follow.next_cursor = @next_cursor
      @follow.save
      follow_set
    end

    def after_done
      @current_user_local.total_follows = @client.user @follow.current_user_id
      @current_user_local.save

      total_follows = @current_user_local.total_follows
      total_allowed_follows = @current_user_local.total_allowed_follows
      unfinished = Follow.where_unfinished

      if total_follows >= total_allowed_follows
        UnfollowJob.perform_async
      elsif Follow.where_unfinished.count >= 1
        FollowJob.perform_async Follow.where_unfinished.first
      end
    end

    def debug(message)
      if @debug_mode
        if message
          stars = "*****************************"
          puts "#{stars} #{message} #{stars}"
        end
      end
    end

    @keep_going = true

    @follow.status = 'following'
    @follow.jid = jid
    @follow.total_followers = @chosen_user[:counts][:followed_by]
    save_follow

    @redundant_follow_count = 0
    max_follow_retries = 11


    loop do
      follow_set = next_follow_set

      follow_set.each do |follower|

        if followed_everyone?
          debug 'Followed everyone'
          @follow.status = 'Will start unfollowing when account reaches follow limit'
          @follow.following_done = true
          save_follow
          @keep_going = false
          break
        elsif cancelled?
          debug 'cancelled'
          @follow.status = 'Will start unfollowing when account reaches follow limit'
          @follow.cancelled = true
          save_follow
          @keep_going = false
          break
        elsif user_exceeded_follow_limit?
          debug 'user exceeded follow limit'
          @follow.status = 'Follow limit reached. Queue to start unfollowing'
          save_follow
          @keep_going = false
        elsif @redundant_follow_count >= max_follow_retries
          @follow.status = 'Following done. Queued to start unfollowing when account reaches follow limit'
          debug 'max follow retries reached'
          @follow.following_done = true
          save_follow
          @keep_going = false
          break
        end

        def follow(follower)
          debug 'follow'
          begin
            if @debug_mode and (@temp_limit >= @total_allowed_follows)
              raise Instagram::RateLimitExceeded.new
            end

            follow_request = @debug_mode ? true : @client.follow_user(follower.id)

            debug follow_request

            if follow_request and @follow.follow_ids.exclude?(follower.id.to_i)
              debug "adding follower to skipped ids. count is #{@follow.follow_count}"
              @follow.follow_ids << follower.id.to_i
            else
              debug 'already followed'
              @redundant_follow_count += 1
            end
          rescue Instagram::RateLimitExceeded
            delay = @debug_mode ? 5.seconds : 61.minutes
            @follow.status = "Hourly limit exceeded. Will resume at #{delay.from_now.to_formatted_s(:time)}"
            save_follow
            FollowJob.perform_in delay, @follow.id
            @keep_going = false
          end
        end

        def skip(follower)
          debug 'skip'
          if @follow.skipped_ids.exclude? follower.id.to_i
            debug "adding follower to skipped ids. count is #{@follow.skipped_count}"
            @follow.skipped_ids << follower.id.to_i
          else
            debug 'already skipped'
          end
          save_follow
        end

        # unless a follow request has already been sent, follow the follower
        begin
          relationship = @client.user_relationship(follower.id).outgoing_status
          debug relationship
          if %w(follows requested).exclude? relationship
            follow follower
          else
            skip follower
          end
        rescue Instagram::Error
          debug 'phew, barely saved the relationship'
          save_follow
        end

        sleep 1 unless @debug_mode

        save_follow
        break unless @keep_going # follow each loop
      end
      debug "leaving followset loop, keep going is #{@keep_going}"
      unless @keep_going # container loop
        after_done
        break
      end
    end
    debug "leaving container loop, keep going is #{@keep_going}"
  end
end


