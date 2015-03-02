class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :authenticate_user!, :init

  def init
    unless current_user.nil?
      @access_token = current_user[:oauth_token]

      #TODO: refactor arguments for statement below in variables
      @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: current_user.oauth_token
      @current_user = @client.user
    end
  end
end
