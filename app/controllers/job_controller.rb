class JobController < ApplicationController

  def index

  end

  def follow
    user_id = params[:id]

    @profile = @client.user user_id

    @queue = Follow.where_unfinished

    follow = Follow.create chosen_user_id: user_id, current_user_id: current_user.id, total_followers: @profile[:counts][:followed_by]

    if @queue.count == 1
      FollowJob.perform_async follow.id
    end

    redirect_to '/'
  end

  def cancel
    follow_id = params[:job_id]
    follow = Follow.find follow_id
    follow.cancelled = true
    follow.save
    redirect_to :back
  end

  def remove
    job_id = params[:job_id]
    Follow.find(job_id).destroy
    redirect_to :back
  end
end

