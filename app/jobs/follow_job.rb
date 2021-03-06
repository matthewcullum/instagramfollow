class FollowJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(current_user_id)
    instagram_service = InstagramService.new current_user_id
    instagram_service.start_follow_routine
  end
end


