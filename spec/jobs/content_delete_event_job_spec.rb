require 'spec_helper'

describe ContentDeleteEventJob do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }
  let(:file_set) { create(:file_set, title: ['Hamlet'], user: user) }
  let(:generic_work) { create(:generic_work, title: ['BethsMac'], user: user) }
  let(:mock_time) { Time.zone.at(1) }
  after do
    Redis.current.keys('events:*').each { |key| Redis.current.del key }
    Redis.current.keys('User:*').each { |key| Redis.current.del key }
    Redis.current.keys('FileSet:*').each { |key| Redis.current.del key }
    Redis.current.keys('GenericWork:*').each { |key| Redis.current.del key }
  end
  it "logs the event to the depositor's profile and followers' dashboards" do
    another_user.follow(user)
    third_user.follow(user)
    expect(user.profile_events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(mock_time)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has deleted file '#{file_set.id}'", timestamp: '1' }
    described_class.perform_now(file_set.id, user.user_key)
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
  end
end
