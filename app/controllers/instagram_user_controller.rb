class InstagramUserController < ApplicationController
  def profile
    begin
      @profile = @client.user(params[:id])
      @followed_by_count = @profile.counts.followed_by
        #@profile = @client.user(1510554860)
    rescue Instagram::BadRequest
      @error = 'Sorry, but this account is private'
    end
  end

  def search
    search_term = params[:search_term]
    @search = @client.user_search search_term, count: 8

    @search_results = []
    @search.each do |result|
      begin
        user = @client.user(result.id)
        @search_results << user
      rescue
        nil
      end
    end
  end
end
