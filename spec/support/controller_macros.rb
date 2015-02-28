module ControllerMacros
  def login_user
    before(:each) do
      user = {:provider => 'instagram',
              :uid => '123545',
              :oauth_token => '1408175505.0fddc3c.63f19b32b49d4573b5c62a8c24663c8b'}
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(user)
      request.env["devise.mapping"] = Devise.mappings[:user] # If using Devise
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:instagram]

      user = FactoryGirl.create(:user, user)
      # user.confirm! # or set a confirmed_at inside the factory. Only necessary if you are using the "confirmable" module
      sign_in user
    end
  end
end