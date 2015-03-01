class InstagramController < ApplicationController
  layout 'dashboard'

  def search
    search_term = params[:search_term]
    @search_results = @client.user_search search_term
  end

  def view_profile
    @profile = @client.user(params[:id])
    #byebug
    FollowJob.perform_later 1286440299, @access_token


  end
end
