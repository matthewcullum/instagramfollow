class FollowJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(chosen_user_id, current_user_id, access_token, *args)
    options = args.extract_options!

    client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: access_token

    current_user = User.find(current_user_id)
    @chosen_user = client.user(chosen_user_id)

    follow = Follow.where(chosen_user_id: chosen_user_id, current_user_id: current_user_id).first_or_create
    follow.status = 'following'
    follow.total_followers = chosen_user[:counts][:followed_by]
    follow.save

    @total_allowed_follows = 6000

    @next_cursor = follow.next_cursor || 0
    @current_follow_set = nil

    @completed = false


    def update_follow
      follow.reload
    end

    def save_follow
      follow.save
    end

    def update_user
      user.reload
    end

    def cancelled?
      follow.reload
      follow.cancelled
    end

    def should_stop?
      # return cancelled? or
    end

    def followed_everyone?(current_follower_id)
      update_follow
      follow.follow_ids.include? current_follower_id
    end

    def user_exceeded_follow_limit?
      update_user

    end

    def next_follow_set
      follow_set = client.user_followed_by @chosen_user[:id], next_cursor: @next_cursor
      @next_cursor = follow_set.pagination.next_cursor
      follow.next_cursor = @next_cursor
      follow.save
      follow_set
    end

    def queue_unfollow_job
      UnfollowJob.perform_async chosen_user_id, access_token
    end

    def follow_next_follower_set
      next_follow_set.each do |follower|

        # if the array of ids we've already followed include the current, we need to break. we've looped around
        if followed_everyone?
          follow.status = 'queued for unfollow'
          @completed = true
          follow.finished = true
          save_follow
          break

        elsif cancelled?
          queue_unfollow_job
          break

        elsif user_exceeded_follow_limit?
          follow.next_cursor = next_cursor
          save_follow
          queue_unfollow_job
        end

        # unless a follow request has already been sent, follow the follower
        unless %w(follows requested).include? client.user_relationship(follower.id).outgoing_status
          follow_request = follow.follow_ids.push follower.id
          follow.follow_count += 1 if follow_request
          save_follow
        end

        follow_next_follower_set
      end
    end



  end
  # loop through followers, following one at a time

end
