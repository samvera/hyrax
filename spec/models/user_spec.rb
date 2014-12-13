require 'spec_helper'

describe User, :type => :model do
  before(:all) do
    @user = FactoryGirl.find_or_create(:jill)
    @another_user = FactoryGirl.find_or_create(:archivist)
  end
  after(:all) do
    @user.destroy
    @another_user.destroy
  end
  it "should have an email" do
    expect(@user.user_key).to eq("jilluser@example.com")
  end
  it "should have activity stream-related methods defined" do
    expect(@user).to respond_to(:stream)
    expect(@user).to respond_to(:events)
    expect(@user).to respond_to(:profile_events)
    expect(@user).to respond_to(:create_event)
    expect(@user).to respond_to(:log_event)
    expect(@user).to respond_to(:log_profile_event)
  end
  it "should have social attributes" do
    expect(@user).to respond_to(:twitter_handle)
    expect(@user).to respond_to(:facebook_handle)
    expect(@user).to respond_to(:googleplus_handle)
    expect(@user).to respond_to(:linkedin_handle)
    expect(@user).to respond_to(:orcid)
  end
  describe 'ORCID validation and normalization' do
    it 'saves when a valid bare ORCID is supplied' do
      @user.orcid = '0000-0000-1111-2222'
      expect(@user).to be_valid
      expect(@user.save).to be true
    end
    it 'saves when a valid ORCID URI is supplied' do
      @user.orcid = 'http://orcid.org/0000-0000-1111-2222'
      expect(@user).to be_valid
      expect(@user.save).to be true
    end
    it 'normalizes bare ORCIDs to URIs' do
      @user.orcid = '0000-0000-1111-2222'
      @user.save
      expect(@user.orcid).to eq 'http://orcid.org/0000-0000-1111-2222'
    end
    it 'marks bad ORCIDs as invalid' do
      @user.orcid = '000-000-111-222'
      expect(@user).not_to be_valid
      expect(@user.save).to be false
    end
  end
  it "should redefine to_param to make redis keys more recognizable (and useable within Rails URLs)" do
    expect(@user.to_param).to eq("jilluser@example-dot-com")
  end
  it "should have a cancan ability defined" do
    expect(@user).to respond_to(:can?)
  end
  it "should not have any followers" do
    expect(@user.followers_count).to eq(0)
    expect(@another_user.follow_count).to eq(0)
  end
  describe "follow/unfollow" do
    before(:all) do
      @user = FactoryGirl.find_or_create(:jill)
      @another_user = FactoryGirl.find_or_create(:archivist)
      @user.follow(@another_user)
    end
    after do
      @user.delete
      @another_user.delete
    end
    it "should be able to follow another user" do
      expect(@user).to be_following(@another_user)
      expect(@another_user).to_not be_following(@user)
      expect(@another_user).to be_followed_by(@user)
      expect(@user).to_not be_followed_by(@another_user)
    end
    it "should be able to unfollow another user" do
      @user.stop_following(@another_user)
      expect(@user).to_not be_following(@another_user)
      expect(@another_user).to_not be_followed_by(@user)
    end
  end

  describe "trophy_files" do
    let(:user) { @user }
    let(:file1) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } }
    let(:file2) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } }
    let(:file3) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } }
    let!(:trophy1) { user.trophies.create!(generic_file_id: file1.noid) }
    let!(:trophy2) { user.trophies.create!(generic_file_id: file2.noid) }
    let!(:trophy3) { user.trophies.create!(generic_file_id: file3.noid) }

    it "should return a list of generic files" do
      expect(user.trophy_files).to eq [file1, file2, file3]
    end

  end

  describe "activity streams" do
    let(:now){DateTime.now.to_i}
    let(:user) { @user }
    let(:activities) {
        [{ action: 'so and so edited their profile', timestamp: now },
        { action: 'so and so uploaded a file', timestamp: (now - 360 ) }]
    }
    let(:file_activities) {
      [{ action: 'uploaded a file', timestamp: now + 1 }]
    }

    before do
      allow(user).to receive(:events).and_return(activities)
      allow(user).to receive(:profile_events).and_return(file_activities)
    end

    it "gathers the user's recent activity within the default amount of time" do
      expect(user.get_all_user_activity).to eq(file_activities.concat(activities))
    end

    it "gathers the user's recent activity within a given timestamp" do
      expect(user.get_all_user_activity(now-60)).to eq(file_activities.concat([activities.first]))
    end
  end
  describe "proxy_deposit_rights" do
    before do
      @subject = FactoryGirl.create :curator
      @user1 = FactoryGirl.create :jill
      @user2 = FactoryGirl.create :archivist
      @subject.can_receive_deposits_from << @user1
      @subject.can_make_deposits_for << @user2
      @subject.save!
    end
    it "can_receive_deposits_from" do
      expect(@subject.can_receive_deposits_from.to_a).to eq [@user1]
      expect(@user1.can_make_deposits_for.to_a).to eq [@subject]
    end
    it "can_make_deposits_for" do
      expect(@subject.can_make_deposits_for.to_a).to eq [@user2]
      expect(@user2.can_receive_deposits_from.to_a).to eq [@subject]
    end
  end
end
