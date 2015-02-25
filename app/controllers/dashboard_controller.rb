class DashboardController < ApplicationController
  layout 'dashboard'

  def index
  end

  def search
    search_term = params['search-term']
    @search_results = @client.user_search search_term
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
