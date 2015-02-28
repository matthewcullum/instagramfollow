class FollowJob
  include SuckerPunch::Job

  def perform(id, access_token)

    ActiveRecord::Base.connection_pool.with_connection do
      client = Instagram.client(access_token: access_token)
      client.user_followed_by
      users = User.first
      Rails.logger.info users
    end
  end
end