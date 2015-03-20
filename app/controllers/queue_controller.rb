class QueueController < ApplicationController

  def index
    # @current_user.subjects.create
    # @current_user.subjects.create waiting: nil

    @queue = @current_user.subjects.unfinished.all.order(busy: :desc)
    @queue_count = @queue.count
    @done = @current_user.subjects.finished.all
  end

  def limits
    render text: @client.utils_raw_response.headers[:x_ratelimit_limit]
  end
end
