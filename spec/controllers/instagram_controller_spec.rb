require 'rails_helper'

RSpec.describe InstagramController, type: :controller do
  login_user

  describe "GET #search" do
    it "returns http success" do
      get :search, search_term: 'asdfjlk'
      expect(response).to have_http_status(:success)
    end

    it "assign a list of profiles to @search_results" do
      get :search, search_term: 'asdfjlk'
      expect(assigns(:search_results)).to be_a(Array)
    end
  end

  describe "GET #view_profile" do
    it "assign a profile to @profile" do
      get :view_profile, id: '459081225'
      expect(assigns(:profile)).to be_a(Hashie::Mash)
    end
  end

end
