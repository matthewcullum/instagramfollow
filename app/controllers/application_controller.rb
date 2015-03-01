class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :authenticate_user!, :init

  def init
    @queue = 2
    unless current_user.nil?
      @access_token = current_user[:oauth_token]
      @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: instagram_token
    end
  end
end
