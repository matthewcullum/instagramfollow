class JobController < ApplicationController

  def init
    super
    @user_id = params[:id]

  end

  def index

  end

  def follow
    @profile = @client.user @user_id

    @queue = Follow.where_unfinished

    follow = Follow.create chosen_user_id: @user_id, current_user_id: current_user.id, total_followers: @profile[:counts][:followed_by]

    if @queue.count == 1
      FollowJob.perform_async follow.id
    end

    redirect_to '/'
  end

  def unfollow
    follow = Follow.where({current_user_id: current_user.id, chosen_user_id: @user_id}).first
    if follow.status == 'following'
      follow.cancelled = true
      follow.save
      UnfollowJob.perform_async follow.id, @access_token
    else
      follow.status == 'waiting'
      UnfollowJob.perform_async follow.id, @access_token
    end
    redirect_to '/'
  end
end
