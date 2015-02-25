class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :authenticate_user!, :init

  def init
    @queue = session[:queue] || 0

    unless current_user.nil?
      @access_token = current_user[:oauth_token]
    end

    unless @access_token.nil?
      @client = Instagram.client(access_token: @access_token)
    end
  end
end
