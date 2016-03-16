require 'spec_helper'

describe UserFollowEventJob do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }
  let(:mock_time) { Time.zone.at(1) }
  after do
    Redis.current.keys('events:*').each { |key| Redis.current.del key }
    Redis.current.keys('User:*').each { |key| Redis.current.del key }
    Redis.current.keys('FileSet:*').each { |key| Redis.current.del key }
    Redis.current.keys('GenericWork:*').each { |key| Redis.current.del key }
  end
  it "logs user follow events" do
    # UserFollow should log the event to the follower's dashboard, the followee's dashboard, and followers' dashboards
    third_user.follow(user)
    expect(user.events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(mock_time)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> is now following <a href=\"/users/#{another_user.to_param}\">#{another_user.user_key}</a>", timestamp: '1' }
    described_class.perform_now(user.user_key, another_user.user_key)
    expect(user.events.length).to eq(1)
    expect(user.events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
  end
end
