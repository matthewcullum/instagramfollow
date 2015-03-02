class DashboardController < ApplicationController
  layout 'dashboard'

  def index
    @queue = Follow.all
    @queue_count = @queue.count
  end

  def playground
    follow_count = @client.user_follows
    render text: users
  end
end
