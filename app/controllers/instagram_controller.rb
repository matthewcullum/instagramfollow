class InstagramController < ApplicationController
  layout 'dashboard'

  def search
    search_term = params[:search_term]
    @search_results = @client.user_search search_term
  end

  def view_profile
    #@profile = @client.user(params[:id])
    @profile = @client.user(1510554860)
    #byebug
    FollowJob.perform_now @profile, current_user, @access_token
  end

  def limits
    render text: '<pre>'+@client.user_followed_by(4).to_s+'</pre>'.html_safe
  end
end
