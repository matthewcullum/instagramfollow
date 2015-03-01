class FollowJob < ActiveJob::Base
  queue_as :default

  def perform(chosen_user, current_user, client, *args)
    #options = args.extract_options!

    @chosen_user = chosen_user
    @current_user = current_user
    @client = client

    @followed_by_count = chosen_user[:counts][:followed_by]
    @followed_count = 0

    @next_cursor = 0

    loop do
      @followed_by = @client.user_followed_by chosen_user[:id], next_cursor: @next_cursor

      @followed_by.each do |follower|
        try
        @client.follow_user follower.id

        @followed_count += 1
        sleep(1)
      end

      @next_cursor = @followed_by.pagination.next_cursor

      break unless @next_cursor
    end

  end
end
