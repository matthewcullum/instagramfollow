class UnfollowJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(follow_id, *args)
    options = args.extract_options!

    @follow = Follow.find follow_id
    @current_user_local = User.where({uid: @follow.current_user_id}).first

    @access_token = @current_user_local.oauth_token
    @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: @access_token

    @current_user = @client.user @follow.current_user_id

    @chosen_user = @client.user(@follow.chosen_user_id)

    @follow.status = 'unfollowing'
    @follow.save

    loop do

      unfollow_id = @follow.follow_ids.shift

      if unfollow_id.nil?
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
          @client.unfollow_user unfollow_id
          @follow.follow_count -= 1
          @follow.unfollow_count += 1
          @follow.save
        rescue
          UnfollowJob.perform_in 1.hour, @follow.id
        end
      end
    end
  end
end