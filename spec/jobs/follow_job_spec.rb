require 'rails_helper'

RSpec.describe FollowJob, type: :job do
  it 'queues a job' do
    expect(FollowJob.perform_async(1,2,3)).to equal 2
  end
end
