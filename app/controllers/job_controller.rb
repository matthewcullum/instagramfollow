class JobController < ApplicationController

  def index

  end

  def follow
    user_id = params[:id]

    @profile = @client.user user_id

    @queue = User.find(@current_user.id).subjects.pending
    subject = @current_user.subjects.where(instagram_id: user_id).first_or_create

    unless Rails.env.test?
      FollowJob.perform_async @current_user.id
    end

    redirect_to '/'
  end

  def cancel
    follow = @current_user.subjects.find params[:job_id]
    follow.cancelled = true
    follow.save
    redirect_to :back
  end

  def remove
    job_id = params[:job_id]
    Subject.find(job_id).destroy
    redirect_to :back
  end
end

