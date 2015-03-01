class FollowJob < ActiveJob::Base
  queue_as :default

  def perform(user_id, instagram_token, *args)
    options = args.extract_options!

    client = Instagram.client access_token: instagram_token
    user_followed_by = client.user_followed_by user_id

  end
end
