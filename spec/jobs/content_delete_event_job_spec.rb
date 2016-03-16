require 'spec_helper'

describe ContentDeleteEventJob do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }
  let(:file_set) { create(:file_set, title: ['Hamlet'], user: user) }
  let(:generic_work) { create(:generic_work, title: ['BethsMac'], user: user) }
  let(:mock_time) { Time.zone.at(1) }
  let(:event) { { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has deleted file '#{file_set.id}'", timestamp: '1' } }

  before do
    another_user.follow(user)
    third_user.follow(user)
    allow(Time).to receive(:now).and_return(mock_time)
  end

  it "logs the event to the depositor's profile and followers' dashboards" do
    expect {
      described_class.perform_now(file_set.id, user.user_key)
    }.to change { user.profile_events.length }.by(1)
      .and change { another_user.events.length }.by(1)
      .and change { third_user.events.length }.by(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.first).to eq(event)
  end
end
