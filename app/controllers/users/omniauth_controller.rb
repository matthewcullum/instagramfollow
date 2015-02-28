class Users::OmniauthController < Devise::OmniauthCallbacksController

  def instagram
    @user = User.from_omniauth(request.env['omniauth.auth'])
    unless @user.persisted?
      @user.save
    end
    sign_in @user
    redirect_to '/'
  end

  def failure
    render text: 'sign in failure'
  end
end