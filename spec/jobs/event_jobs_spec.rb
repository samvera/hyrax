require 'spec_helper'

describe 'event jobs' do
  before do
    @user = FactoryGirl.find_or_create(:jill)
    @another_user = FactoryGirl.find_or_create(:archivist)
    @third_user = FactoryGirl.find_or_create(:curator)
    @gf = GenericFile.new(id: 'test-123')
    @gf.apply_depositor_metadata(@user)
    @gf.title = ['Hamlet']
    @gf.save
  end
  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('GenericFile:*').each { |key| $redis.del key }
  end
  it "should log user edit profile events" do
    # UserEditProfile should log the event to the editor's dashboard and his/her followers' dashboards
    @another_user.follow(@user)
    count_user = @user.events.length
    count_another = @another_user.events.length
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has edited his or her profile', timestamp: '1' }
    UserEditProfileEventJob.new(@user.user_key).run
    expect(@user.events.length).to eq(count_user + 1)
    expect(@user.events.first).to eq(event)
    expect(@another_user.events.length).to eq(count_another + 1)
    expect(@another_user.events.first).to eq(event)
  end
  it "should log user follow events" do
    # UserFollow should log the event to the follower's dashboard, the followee's dashboard, and followers' dashboards
    @third_user.follow(@user)
    expect(@user.events.length).to eq(0)
    expect(@another_user.events.length).to eq(0)
    expect(@third_user.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> is now following <a href="/users/archivist1@example-dot-com">archivist1@example.com</a>', timestamp: '1' }
    UserFollowEventJob.new(@user.user_key, @another_user.user_key).run
    expect(@user.events.length).to eq(1)
    expect(@user.events.first).to eq(event)
    expect(@another_user.events.length).to eq(1)
    expect(@another_user.events.first).to eq(event)
    expect(@third_user.events.length).to eq(1)
    expect(@third_user.events.first).to eq(event)
  end
  it "should log user unfollow events" do
    # UserUnfollow should log the event to the unfollower's dashboard, the unfollowee's dashboard, and followers' dashboards
    @third_user.follow(@user)
    @user.follow(@another_user)
    expect(@user.events.length).to eq(0)
    expect(@another_user.events.length).to eq(0)
    expect(@third_user.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = { action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has unfollowed <a href="/users/archivist1@example-dot-com">archivist1@example.com</a>', timestamp: '1' }
    UserUnfollowEventJob.new(@user.user_key, @another_user.user_key).run
    expect(@user.events.length).to eq(1)
    expect(@user.events.first).to eq(event)
    expect(@another_user.events.length).to eq(1)
    expect(@another_user.events.first).to eq(event)
    expect(@third_user.events.length).to eq(1)
    expect(@third_user.events.first).to eq(event)
  end
  it "should log content deposit events" do
    # ContentDeposit should log the event to the depositor's profile, followers' dashboards, and the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    expect(@user.profile_events.length).to eq(0)
    expect(@another_user.events.length).to eq(0)
    expect(@third_user.events.length).to eq(0)
    expect(@gf.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = {action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has deposited <a href="/files/test-123">Hamlet</a>', timestamp: '1' }
    ContentDepositEventJob.new('test-123', @user.user_key).run
    expect(@user.profile_events.length).to eq(1)
    expect(@user.profile_events.first).to eq(event)
    expect(@another_user.events.length).to eq(1)
    expect(@another_user.events.first).to eq(event)
    expect(@third_user.events.length).to eq(1)
    expect(@third_user.events.first).to eq(event)
    expect(@gf.events.length).to eq(1)
    expect(@gf.events.first).to eq(event)
  end
  it "logs content depositor change events" do
    # ContentDepositorChange should log the event to the proxy depositor's profile, the depositor's dashboard, followers' dashboards, and the GF
    @third_user.follow(@another_user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    allow(Time).to receive(:now).at_least(:once).and_return(1)
    event = {action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has transferred <a href="/files/test-123">Hamlet</a> to user <a href="/users/archivist1@example-dot-com">archivist1@example.com</a>', timestamp: '1' }
    ContentDepositorChangeEventJob.new('test-123', @another_user.user_key).run
    expect(@user.profile_events.length).to eq(1)
    expect(@user.profile_events.first).to eq(event)
    expect(@another_user.events.length).to eq(1)
    expect(@another_user.events.first).to eq(event)
    expect(@third_user.events.length).to eq(1)
    expect(@third_user.events.first).to eq(event)
    expect(@gf.events.length).to eq(1)
    expect(@gf.events.first).to eq(event)
  end
  it "should log content update events" do
    # ContentUpdate should log the event to the depositor's profile, followers' dashboards, and the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    expect(@user.profile_events.length).to eq(0)
    expect(@another_user.events.length).to eq(0)
    expect(@third_user.events.length).to eq(0)
    expect(@gf.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = {action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has updated <a href="/files/test-123">Hamlet</a>', timestamp: '1' }
    ContentUpdateEventJob.new('test-123', @user.user_key).run
    expect(@user.profile_events.length).to eq(1)
    expect(@user.profile_events.first).to eq(event)
    expect(@another_user.events.length).to eq(1)
    expect(@another_user.events.first).to eq(event)
    expect(@third_user.events.length).to eq(1)
    expect(@third_user.events.first).to eq(event)
    expect(@gf.events.length).to eq(1)
    expect(@gf.events.first).to eq(event)
  end
  it "should log content new version events" do
    # ContentNewVersion should log the event to the depositor's profile, followers' dashboards, and the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    expect(@user.profile_events.length).to eq(0)
    expect(@another_user.events.length).to eq(0)
    expect(@third_user.events.length).to eq(0)
    expect(@gf.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = {action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has added a new version of <a href="/files/test-123">Hamlet</a>', timestamp: '1' }
    ContentNewVersionEventJob.new('test-123', @user.user_key).run
    expect(@user.profile_events.length).to eq(1)
    expect(@user.profile_events.first).to eq(event)
    expect(@another_user.events.length).to eq(1)
    expect(@another_user.events.first).to eq(event)
    expect(@third_user.events.length).to eq(1)
    expect(@third_user.events.first).to eq(event)
    expect(@gf.events.length).to eq(1)
    expect(@gf.events.first).to eq(event)
  end
  it "should log content restored version events" do
    # ContentRestoredVersion should log the event to the depositor's profile, followers' dashboards, and the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    expect(@user.profile_events.length).to eq(0)
    expect(@another_user.events.length).to eq(0)
    expect(@third_user.events.length).to eq(0)
    expect(@gf.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = {action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has restored a version \'content.0\' of <a href="/files/test-123">Hamlet</a>', timestamp: '1' }
    ContentRestoredVersionEventJob.new('test-123', @user.user_key, 'content.0').run
    expect(@user.profile_events.length).to eq(1)
    expect(@user.profile_events.first).to eq(event)
    expect(@another_user.events.length).to eq(1)
    expect(@another_user.events.first).to eq(event)
    expect(@third_user.events.length).to eq(1)
    expect(@third_user.events.first).to eq(event)
    expect(@gf.events.length).to eq(1)
    expect(@gf.events.first).to eq(event)
  end
  it "should log content delete events" do
    # ContentDelete should log the event to the depositor's profile and followers' dashboards
    @another_user.follow(@user)
    @third_user.follow(@user)
    expect(@user.profile_events.length).to eq(0)
    expect(@another_user.events.length).to eq(0)
    expect(@third_user.events.length).to eq(0)
    expect(Time).to receive(:now).at_least(:once).and_return(1)
    event = {action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has deleted file \'test-123\'', timestamp: '1' }
    ContentDeleteEventJob.new('test-123', @user.user_key).run
    expect(@user.profile_events.length).to eq(1)
    expect(@user.profile_events.first).to eq(event)
    expect(@another_user.events.length).to eq(1)
    expect(@another_user.events.first).to eq(event)
    expect(@third_user.events.length).to eq(1)
    expect(@third_user.events.first).to eq(event)
  end
  it "should not log content-related jobs to followers who lack access" do
    # No Content-related eventjobs should log an event to a follower who does not have access to the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    expect(@user.profile_events.length).to eq(0)
    expect(@another_user.events.length).to eq(0)
    expect(@third_user.events.length).to eq(0)
    expect(@gf.events.length).to eq(0)
    @now = Time.now
    expect(Time).to receive(:now).at_least(:once).and_return(@now)
    event = {action: 'User <a href="/users/jilluser@example-dot-com">jilluser@example.com</a> has updated <a href="/files/test-123">Hamlet</a>', timestamp: @now.to_i.to_s }
    ContentUpdateEventJob.new('test-123', @user.user_key).run
    expect(@user.profile_events.length).to eq(1)
    expect(@user.profile_events.first).to eq(event)
    expect(@another_user.events.length).to eq(0)
    expect(@another_user.events.first).to be_nil
    expect(@third_user.events.length).to eq(0)
    expect(@third_user.events.first).to be_nil
    expect(@gf.events.length).to eq(1)
    expect(@gf.events.first).to eq(event)
  end
end
