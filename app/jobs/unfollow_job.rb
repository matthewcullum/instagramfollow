class UnfollowJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(current_user_id, *args)
    options = args.extract_options!

    @current_user_local = User.find_by_uid current_user_id
    follow_id = options[:follow_id]
    puts "************************args: #{args}, options: #{options}*********************************"
    @follow = follow_id ? Follow.find(follow_id) : Follow.by_uid(current_user_id).last
    @cancelled = @follow.cancelled

    @buffer = 500

    if @follow and @follow.follow_ids.count

      @access_token = @current_user_local.oauth_token
      @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: @access_token

      @current_user = @client.user @follow.current_user_id

      @chosen_user = @client.user(@follow.chosen_user_id)
      @total_follows = @chosen_user[:counts][:follows]
      @just_unfollowed = 0

      @follow.status = 'unfollowing'
      @follow.save

      @debug_mode = true

      loop do

        unfollow_id = @follow.follow_ids.shift

        if unfollow_id.nil? or @just_unfollowed >= @buffer
          if @follow.following_done
            @follow.finished = true
            @follow.status = 'Finished'

          elsif @follow.cancelled
            @follow.finished = true
            @follow.status = 'Cancelled'

          else
            FollowJob.perform_async @follow.id
          end

          @follow.save
          break

        else
          begin
            unless @debug_mode
              @client.unfollow_user unfollow_id
            end
            @follow.follow_count -= 1
            @follow.unfollow_count += 1
            @just_unfollowed += 1
            @follow.save
            unless @debug_mode
              sleep 1
            end
          rescue
            delay = @debug_mode ? 61.minutes : 5.seconds
            @follow.status = "Hourly limit exceeded. Will resume unfollowing at #{delay.from_now.to_formatted_s(:time)}"
            UnfollowJob.perform_in delay, @follow.id
          end
        end
      end
    end
  end
end