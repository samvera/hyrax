require 'spec_helper'

describe 'event jobs' do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }
  let(:file_set) { create(:file_set, title: ['Hamlet'], user: user) }
  let(:generic_work) { create(:generic_work, title: ['BethsMac'], user: user) }
  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('FileSet:*').each { |key| $redis.del key }
    $redis.keys('GenericWork:*').each { |key| $redis.del key }
  end
  it "logs user edit profile events" do
    # UserEditProfile should log the event to the editor's dashboard and his/her followers' dashboards
    another_user.follow(user)
    count_user = user.events.length
    count_another = another_user.events.length
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has edited his or her profile", timestamp: '1' }
    UserEditProfileEventJob.perform_now(user.user_key)
    expect(user.events.length).to eq(count_user + 1)
    expect(user.events.first).to eq(event)
    expect(another_user.events.length).to eq(count_another + 1)
    expect(another_user.events.first).to eq(event)
  end
  it "logs user follow events" do
    # UserFollow should log the event to the follower's dashboard, the followee's dashboard, and followers' dashboards
    third_user.follow(user)
    expect(user.events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> is now following <a href=\"/users/#{another_user.to_param}\">#{another_user.user_key}</a>", timestamp: '1' }
    UserFollowEventJob.perform_now(user.user_key, another_user.user_key)
    expect(user.events.length).to eq(1)
    expect(user.events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
  end
  it "logs user unfollow events" do
    # UserUnfollow should log the event to the unfollower's dashboard, the unfollowee's dashboard, and followers' dashboards
    third_user.follow(user)
    user.follow(another_user)
    expect(user.events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has unfollowed <a href=\"/users/#{another_user.to_param}\">#{another_user.user_key}</a>", timestamp: '1' }
    UserUnfollowEventJob.perform_now(user.user_key, another_user.user_key)
    expect(user.events.length).to eq(1)
    expect(user.events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
  end
  it "logs content deposit events" do
    # ContentDeposit should log the event to the depositor's profile, followers' dashboards, and the FS
    another_user.follow(user)
    third_user.follow(user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    expect(user.profile_events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(file_set.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has deposited <a href=\"/concern/file_sets/#{file_set.id}\">Hamlet</a>", timestamp: '1' }
    ContentDepositEventJob.perform_now(file_set.id, user.user_key)
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
    expect(file_set.events.length).to eq(1)
    expect(file_set.events.first).to eq(event)
  end
  it "logs content depositor change events" do
    # ContentDepositorChange should log the event to the proxy depositor's profile, the depositor's dashboard, followers' dashboards, and the FS
    third_user.follow(another_user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has transferred <a href=\"/concern/generic_works/#{generic_work.id}\">BethsMac</a> to user <a href=\"/users/#{another_user.to_param}\">#{another_user.user_key}</a>", timestamp: '1' }
    allow(Time).to receive(:now).at_least(:once).and_return(1)
    ContentDepositorChangeEventJob.perform_now(generic_work.id, another_user.user_key)
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
    expect(generic_work.events.length).to eq(1)
    expect(generic_work.events.first).to eq(event)
  end
  it "logs content update events" do
    # ContentUpdate should log the event to the depositor's profile, followers' dashboards, and the FS
    another_user.follow(user)
    third_user.follow(user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    expect(user.profile_events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(file_set.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has updated <a href=\"/concern/file_sets/#{file_set.id}\">Hamlet</a>", timestamp: '1' }
    ContentUpdateEventJob.perform_now(file_set.id, user.user_key)
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
    expect(file_set.events.length).to eq(1)
    expect(file_set.events.first).to eq(event)
  end
  it "logs content new version events" do
    # ContentNewVersion should log the event to the depositor's profile, followers' dashboards, and the FS
    another_user.follow(user)
    third_user.follow(user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    expect(user.profile_events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(file_set.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has added a new version of <a href=\"/concern/file_sets/#{file_set.id}\">Hamlet</a>", timestamp: '1' }
    ContentNewVersionEventJob.perform_now(file_set.id, user.user_key)
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
    expect(file_set.events.length).to eq(1)
    expect(file_set.events.first).to eq(event)
  end
  it "logs content restored version events" do
    # ContentRestoredVersion should log the event to the depositor's profile, followers' dashboards, and the FS
    another_user.follow(user)
    third_user.follow(user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    expect(user.profile_events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(file_set.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has restored a version 'content.0' of <a href=\"/concern/file_sets/#{file_set.id}\">Hamlet</a>", timestamp: '1' }
    ContentRestoredVersionEventJob.perform_now(file_set.id, user.user_key, 'content.0')
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
    expect(file_set.events.length).to eq(1)
    expect(file_set.events.first).to eq(event)
  end
  it "logs content delete events" do
    # ContentDelete should log the event to the depositor's profile and followers' dashboards
    another_user.follow(user)
    third_user.follow(user)
    expect(user.profile_events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has deleted file '#{file_set.id}'", timestamp: '1' }
    ContentDeleteEventJob.perform_now(file_set.id, user.user_key)
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.length).to eq(1)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.length).to eq(1)
    expect(third_user.events.first).to eq(event)
  end
  it "does not log content-related jobs to followers who lack access" do
    # No Content-related eventjobs should log an event to a follower who does not have access to the FS
    another_user.follow(user)
    third_user.follow(user)
    expect(user.profile_events.length).to eq(0)
    expect(another_user.events.length).to eq(0)
    expect(third_user.events.length).to eq(0)
    expect(file_set.events.length).to eq(0)
    @now = Time.now
    expect(Time).to receive(:now).at_least(:once).and_return(@now)
    event = { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has updated <a href=\"/concern/file_sets/#{file_set.id}\">Hamlet</a>", timestamp: @now.to_i.to_s }
    ContentUpdateEventJob.perform_now(file_set.id, user.user_key)
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.length).to eq(0)
    expect(another_user.events.first).to be_nil
    expect(third_user.events.length).to eq(0)
    expect(third_user.events.first).to be_nil
    expect(file_set.events.length).to eq(1)
    expect(file_set.events.first).to eq(event)
  end
end
