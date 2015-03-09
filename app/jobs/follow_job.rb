class FollowJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(follow_id, *args)

    options = args.extract_options!

    @follow = Follow.find follow_id
    @current_user_local = User.find_by_uid @follow.current_user_id

    @access_token = @current_user_local.oauth_token
    @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: @access_token

    @current_user = @client.user @follow.current_user_id

    @chosen_user = @client.user(@follow.chosen_user_id)

    @total_allowed_follows = @current_user_local.total_allowed_follows

    @next_cursor = @follow.next_cursor

    @current_follow_set = nil

    def update_follow
      @follow.save
      @follow.reload
    end

    def save_follow
      @follow.save
    end

    def update_user
      @current_user.reload
    end

    def cancelled?
      @follow.reload
      @follow.cancelled
    end

    def followed_everyone?
      update_follow
      follow_count = @follow.follow_count
      total_followers = @follow.total_followers

      follow_count >= total_followers
    end

    def already_followed?(follower_id)
      update_follow
      follow_ids = @follow.follow_ids
      follow_ids.include? follower_id
    end

    def user_exceeded_follow_limit?
      update_user
      user_total_follows = @current_user[:counts][:follows]
      user_total_follows >= @total_allowed_follows
    end

    def next_follow_set
      @current_cursor = @next_cursor

      follow_set = @client.user_followed_by @chosen_user[:id], next_cursor: @next_cursor
      @next_cursor = follow_set.pagination.next_cursor
      @follow.next_cursor = @next_cursor
      @follow.save
      follow_set
    end

    def queue_unfollow_job
      UnfollowJob.perform_async @follow.id, @access_token
    end

    def log(message)
      stars = "*****************************"
      puts "#{stars} #{message} #{stars}"
    end

    keep_going = true

    @follow.status = 'following'
    @follow.jid = jid
    @follow.total_followers = @chosen_user[:counts][:followed_by]
    save_follow

    redundant_follow_count = 0
    max_follow_retries = 20

    loop do
      follow_set = next_follow_set

      follow_set.each do |follower|

        if followed_everyone?
          log "Followed everyone"
          @follow.status = 'Queueing for unfollow'
          @follow.following_done = true
          save_follow
          queue_unfollow_job
          keep_going = false
          break
        elsif cancelled?
          @follow.cancelled = true
          save_follow
          queue_unfollow_job
          keep_going = false
          break
        elsif user_exceeded_follow_limit?
          keep_going = false
          queue_unfollow_job
        elsif already_followed? follower.id
          redundant_follow_count +=1
          if redundant_follow_count > max_follow_retries
            @follow.following_done = true
            save_follow
            keep_going = false
          end
          break
        end

        # unless a follow request has already been sent, follow the follower
        begin
          relationship = @client.user_relationship(follower.id).outgoing_status

          if %w(follows requested).exclude? relationship
            begin
              follow_request = @client.follow_user follower.id
              log follow_request
              if follow_request
                @follow.follow_ids.push follower.id.to_i
                @follow.follow_count += 1
                save_follow
              end
            rescue
              @follow.status = "Hourly limit exceeded. Will resume at #{1.hours.from_now.to_formatted_s(:time)}"
              save_follow
              keep_going = false
              FollowJob.perform_in 61.minutes, @follow.id
            end
          else
            @follow.follow_count += 1
            save_follow
          end
        rescue
          @follow.follow_count += 1
          save_follow
        end
        break unless keep_going # follow each loop
      end
      break unless keep_going # container loop
    end
  end
end

