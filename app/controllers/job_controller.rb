class JobController < ApplicationController
  @current_user = @client.user
  @user_id = params[:id]

  def index

  end

  def follow
    @profile = @client.user @user_id

    Follow.create chosen_user_id: @user_id, current_user_id: @current_user.id, total_follows: @profile[:counts][:followed_by]
    FollowJob.perform_async @profile.id, @current_user.id, @access_token
    redirect_to '/'
  end

  def unfollow

  end

  def cancel_job
    follow = Follow.where({current_user_id: @current_user.id, chosen_user_id: @user_id})
  end
end
