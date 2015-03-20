require 'rails_helper'

RSpec.describe InstagramUserController, type: :controller do
  login_user
  describe "GET #profile" do
    user_id = 1408175505

    it "responds successfully with an HTTP 200 status code" do
      get :profile, id: user_id
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end
    it "assigns a profile to @profile" do
      get :profile, id: user_id
      expect(assigns(:profile)).to include(full_name: 'Matthew Cullum')
    end
  end

  describe "Get by_keyword" do
    it "returns a list of instagram users" do
      get :search, search_term: 'flower'
      expect(assigns(:search_results)[0]).to include("username"=> 'flower')
    end
  end
end
