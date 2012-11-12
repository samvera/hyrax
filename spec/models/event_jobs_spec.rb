# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'event jobs' do
  before(:each) do
    @user = FactoryGirl.find_or_create(:user)
    @another_user = FactoryGirl.find_or_create(:archivist)
    @third_user = FactoryGirl.find_or_create(:curator)
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    @gf = GenericFile.new(pid: 'test:123')
    @gf.apply_depositor_metadata(@user.login)
    @gf.title = 'Hamlet'
    @gf.save
  end
  after(:each) do
    @gf.delete
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('GenericFile:*').each { |key| $redis.del key }
  end
  it "should log user edit profile events" do
    # UserEditProfile should log the event to the editor's dashboard and his/her followers' dashboards
    @another_user.follow(@user)
    @user.events.length.should == 0
    @another_user.events.length.should == 0
    Time.expects(:now).returns(1).at_least_once
    event = { action: 'User <a href="/users/jilluser">jilluser</a> has edited his or her profile', timestamp: '1' }
    UserEditProfileEventJob.perform(@user.login)
    @user.events.length.should == 1
    @user.events.first.should == event
    @another_user.events.length.should == 1
    @another_user.events.first.should == event
  end
  it "should log user follow events" do
    # UserFollow should log the event to the follower's dashboard, the followee's dashboard, and followers' dashboards
    @third_user.follow(@user)
    @user.events.length.should == 0
    @another_user.events.length.should == 0
    @third_user.events.length.should == 0
    Time.expects(:now).returns(1).at_least_once
    event = { action: 'User <a href="/users/jilluser">jilluser</a> is now following <a href="/users/archivist1">archivist1</a>', timestamp: '1' }
    UserFollowEventJob.perform(@user.login, @another_user.login)
    @user.events.length.should == 1
    @user.events.first.should == event
    @another_user.events.length.should == 1
    @another_user.events.first.should == event
    @third_user.events.length.should == 1
    @third_user.events.first.should == event
  end
  it "should log user unfollow events" do
    # UserUnfollow should log the event to the unfollower's dashboard, the unfollowee's dashboard, and followers' dashboards
    @third_user.follow(@user)
    @user.follow(@another_user)
    @user.events.length.should == 0
    @another_user.events.length.should == 0
    @third_user.events.length.should == 0
    Time.expects(:now).returns(1).at_least_once
    event = { action: 'User <a href="/users/jilluser">jilluser</a> has unfollowed <a href="/users/archivist1">archivist1</a>', timestamp: '1' }
    UserUnfollowEventJob.perform(@user.login, @another_user.login)
    @user.events.length.should == 1
    @user.events.first.should == event
    @another_user.events.length.should == 1
    @another_user.events.first.should == event
    @third_user.events.length.should == 1
    @third_user.events.first.should == event
  end
  it "should log content deposit events" do
    # ContentDeposit should log the event to the depositor's profile, followers' dashboards, and the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    User.any_instance.stubs(:can?).returns(true)
    @user.profile_events.length.should == 0
    @another_user.events.length.should == 0
    @third_user.events.length.should == 0
    @gf.events.length.should == 0
    Time.expects(:now).returns(1).at_least_once
    event = {action: 'User <a href="/users/jilluser">jilluser</a> has deposited <a href="/files/123">Hamlet</a>', timestamp: '1' }
    ContentDepositEventJob.perform('test:123', @user.login)
    @user.profile_events.length.should == 1
    @user.profile_events.first.should == event
    @another_user.events.length.should == 1
    @another_user.events.first.should == event
    @third_user.events.length.should == 1
    @third_user.events.first.should == event
    @gf.events.length.should == 1
    @gf.events.first.should == event
  end
  it "should log content update events" do
    # ContentUpdate should log the event to the depositor's profile, followers' dashboards, and the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    User.any_instance.stubs(:can?).returns(true)
    @user.profile_events.length.should == 0
    @another_user.events.length.should == 0
    @third_user.events.length.should == 0
    @gf.events.length.should == 0
    Time.expects(:now).returns(1).at_least_once
    event = {action: 'User <a href="/users/jilluser">jilluser</a> has updated <a href="/files/123">Hamlet</a>', timestamp: '1' }
    ContentUpdateEventJob.perform('test:123', @user.login)
    @user.profile_events.length.should == 1
    @user.profile_events.first.should == event
    @another_user.events.length.should == 1
    @another_user.events.first.should == event
    @third_user.events.length.should == 1
    @third_user.events.first.should == event
    @gf.events.length.should == 1
    @gf.events.first.should == event
  end
  it "should log content new version events" do
    # ContentNewVersion should log the event to the depositor's profile, followers' dashboards, and the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    User.any_instance.stubs(:can?).returns(true)
    @user.profile_events.length.should == 0
    @another_user.events.length.should == 0
    @third_user.events.length.should == 0
    @gf.events.length.should == 0
    Time.expects(:now).returns(1).at_least_once
    event = {action: 'User <a href="/users/jilluser">jilluser</a> has added a new version of <a href="/files/123">Hamlet</a>', timestamp: '1' }
    ContentNewVersionEventJob.perform('test:123', @user.login)
    @user.profile_events.length.should == 1
    @user.profile_events.first.should == event
    @another_user.events.length.should == 1
    @another_user.events.first.should == event
    @third_user.events.length.should == 1
    @third_user.events.first.should == event
    @gf.events.length.should == 1
    @gf.events.first.should == event
  end
  it "should log content restored version events" do
    # ContentRestoredVersion should log the event to the depositor's profile, followers' dashboards, and the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    User.any_instance.stubs(:can?).returns(true)
    @user.profile_events.length.should == 0
    @another_user.events.length.should == 0
    @third_user.events.length.should == 0
    @gf.events.length.should == 0
    Time.expects(:now).returns(1).at_least_once
    event = {action: 'User <a href="/users/jilluser">jilluser</a> has restored a version \'content.0\' of <a href="/files/123">Hamlet</a>', timestamp: '1' }
    ContentRestoredVersionEventJob.perform('test:123', @user.login, 'content.0')
    @user.profile_events.length.should == 1
    @user.profile_events.first.should == event
    @another_user.events.length.should == 1
    @another_user.events.first.should == event
    @third_user.events.length.should == 1
    @third_user.events.first.should == event
    @gf.events.length.should == 1
    @gf.events.first.should == event
  end
  it "should log content delete events" do
    # ContentDelete should log the event to the depositor's profile and followers' dashboards
    @another_user.follow(@user)
    @third_user.follow(@user)
    @user.profile_events.length.should == 0
    @another_user.events.length.should == 0
    @third_user.events.length.should == 0
    Time.expects(:now).returns(1).at_least_once
    event = {action: 'User <a href="/users/jilluser">jilluser</a> has deleted file \'test:123\'', timestamp: '1' }
    ContentDeleteEventJob.perform('test:123', @user.login)
    @user.profile_events.length.should == 1
    @user.profile_events.first.should == event
    @another_user.events.length.should == 1
    @another_user.events.first.should == event
    @third_user.events.length.should == 1
    @third_user.events.first.should == event
  end
  it "should not log content-related jobs to followers who lack access" do
    # No Content-related eventjobs should log an event to a follower who does not have access to the GF
    @another_user.follow(@user)
    @third_user.follow(@user)
    @user.profile_events.length.should == 0
    @another_user.events.length.should == 0
    @third_user.events.length.should == 0
    @gf.events.length.should == 0
    @now = Time.now
    Time.expects(:now).returns(@now).at_least_once
    event = {action: 'User <a href="/users/jilluser">jilluser</a> has updated <a href="/files/123">Hamlet</a>', timestamp: @now.to_i.to_s }
    ContentUpdateEventJob.perform('test:123', @user.login)
    @user.profile_events.length.should == 1
    @user.profile_events.first.should == event
    @another_user.events.length.should == 0
    @another_user.events.first.should be_nil
    @third_user.events.length.should == 0
    @third_user.events.first.should be_nil
    @gf.events.length.should == 1
    @gf.events.first.should == event
  end
end

