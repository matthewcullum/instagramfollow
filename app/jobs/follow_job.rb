class FollowJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(chosen_user_id, current_user_id, access_token, *args)
    options = args.extract_options!

    @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: access_token
    @chosen_user = @client.user(chosen_user_id)

    @current_user = current_user_id

    #@followed_by_count = chosen_user[:counts][:followed_by]
    @followed_count = 0
    @next_cursor = options.cursor || 0

    loop do
      @followed_by = @client.user_followed_by @chosen_user[:id], next_cursor: @next_cursor

      @followed_by.each do |follower|
        unless %w(follows requested).include? @client.user_relationship(follower.id).outgoing_status
          Rails.logger.info follower
          # @client.follow_user follower.id
          # @followed_count += 1
          sleep(1)
        end
      end

      @next_cursor = @followed_by.pagination.next_cursor

      break unless @next_cursor
    end

  end
end
