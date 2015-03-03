class JobController < ApplicationController

  def init
    super
    @user_id = params[:id]
  end

  def index

  end

  def follow
    @profile = @client.user @user_id

    Follow.create chosen_user_id: @user_id, current_user_id: @current_user.id, total_followers: @profile[:counts][:followed_by]
    FollowJob.perform_async @profile.id, @current_user.id, @access_token
    redirect_to '/'
  end

  def unfollow
    follow = Follow.where({current_user_id: @current_user.id, chosen_user_id: @user_id})
  end
end
