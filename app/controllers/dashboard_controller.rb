class DashboardController < ApplicationController
  layout 'dashboard'

  def index
  end

  def add_to_queue
    FollowJob.new.async.perform('follow', @access_token)
    render text: params[:id]
  end

  def playground
    follow_count = @client.user_follows
    render text: users
  end
end
