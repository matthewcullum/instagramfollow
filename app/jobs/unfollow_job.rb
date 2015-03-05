class UnfollowJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(follow_id, access_token, *args)
    options = args.extract_options!

    follow = Follow.find(follow_id)
    follow.status = 'unfollowing'

    @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: access_token

    @chosen_user = @client.user(follow.chosen_user_id)
    @current_user = follow.current_user_id

    @next_cursor = options[:cursor] || 0

    loop do
      unfollow_id = follow.follow_ids.pop
      if unfollow_id.nil?
        follow.status = "done"
        follow.save
        break
      else
        @client.unfollow_user unfollow_id
        follow.follow_count -= 1
        follow.unfollow_count += 1
        follow.save
      end
    end
  end
end
