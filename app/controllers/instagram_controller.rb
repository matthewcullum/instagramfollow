class InstagramController < ApplicationController
  layout 'dashboard'

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

  def view_profile
    begin
      @profile = @client.user(params[:id])
      @followed_by_count = @profile.counts.followed_by
        #@profile = @client.user(1510554860)
    rescue Instagram::BadRequest
      @error = 'Sorry, but this account is private'
    end
  end

  def limits
    render text: '<pre>'+@client.user_followed_by(4).to_s+'</pre>'.html_safe
  end
end
