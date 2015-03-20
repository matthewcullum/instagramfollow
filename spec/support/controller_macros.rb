module ControllerMacros
  def login_user
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]

      OmniAuth.config.test_mode = true

      user = {credentials: {token: '1408175505.0fddc3c.63f19b32b49d4573b5c62a8c24663c8b'},
              info: {image: 'alskdfj'},
              provider: 'instagram',
              id: '1408175505',
              username: 'mcullum96',
              full_name: ' Matthew Cullum'
      }
      OmniAuth.config.mock_auth[:instagram] = OmniAuth::AuthHash.new(user)

      auth = OmniAuth.config.mock_auth[:instagram]

      sign_in User.from_omniauth auth
    end
  end
end