require 'rails_helper'

RSpec.describe InstagramService do

  before :each do
    @current_user = create :user
    @follower_id = 24880606
    @subject = @current_user.subjects.create(instagram_id: @follower_id)
    @instagram_service = InstagramService.new @current_user.id
  end

  describe "#get_all_follower_ids" do

    let(:follow_ids) { @instagram_service.get_all_follower_ids }

    it("returns an array") { expect(follow_ids).to be_a(Array) }
    it("isn't empty") { expect(follow_ids).to_not be_empty }
    it("should consist of Fixnums") { expect(follow_ids[0]).to be_a_kind_of(Fixnum) }

  end

  describe "#unfollow_all_in_queue" do
    context "when the subject was just added" do
      it "returns with FINISHED_UNFOLLOWING" do
        expect(@instagram_service.unfollow_all_in_queue(@subject)).to eq(InstagramService::FINISHED_UNFOLLOWING)
      end
    end
  end
  describe "#follow_all_in_queue" do
    context "when the subject was just added" do
      it "returns with FINISHED_UNFOLLOWING" do
        expect(@instagram_service.follow_all_in_queue(@subject)).to eq(InstagramService::FINISHED_FOLLOWING)
      end
    end
  end
end

