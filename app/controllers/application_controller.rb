class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :authenticate_user!, :init
  layout :layout_by_resource

  def init
    unless current_user.nil?
      @access_token = current_user.access_token

      #TODO: refactor arguments for statement below in variables
      @client = Instagram.client client_id: ENV['INSTAGRAM_API_KEY'], client_secret: ENV['INSTAGRAM_SECRET_KEY'], client_ips: '127.0.0.1', access_token: @access_token
      @current_user = User.find current_user.id
    end
  end

  def layout_by_resource
    if devise_controller? && resource_name == :user && action_name == 'new'
      "devise"
    else
      "application"
    end
  end
end
