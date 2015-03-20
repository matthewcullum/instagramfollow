require 'rails_helper'

RSpec.describe JobController, type: :controller do
  login_user
  describe "POST follow" do
    it "Queues a user to be followed" do
      post :follow, id: 24880606
      # expect(current_user.subjects.first).to include(subject_id: 24880606)
      #expect(assigns(:current_user)).to include("hello")
    end
  end
end
