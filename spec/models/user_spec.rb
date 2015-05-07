require 'spec_helper'

describe User, :type => :model do
  let(:user) { FactoryGirl.build(:user) }
  let(:another_user) { FactoryGirl.build(:user) }

  it "should have an email" do
    expect(user.user_key).to be_kind_of String
  end
  it "should have activity stream-related methods defined" do
    expect(user).to respond_to(:stream)
    expect(user).to respond_to(:events)
    expect(user).to respond_to(:profile_events)
    expect(user).to respond_to(:create_event)
    expect(user).to respond_to(:log_event)
    expect(user).to respond_to(:log_profile_event)
  end
  it "should have social attributes" do
    expect(user).to respond_to(:twitter_handle)
    expect(user).to respond_to(:facebook_handle)
    expect(user).to respond_to(:googleplus_handle)
    expect(user).to respond_to(:linkedin_handle)
    expect(user).to respond_to(:orcid)
  end
  describe 'ORCID validation and normalization' do
    it 'saves when a valid bare ORCID is supplied' do
      user.orcid = '0000-0000-1111-2222'
      expect(user).to be_valid
      expect(user.save).to be true
    end
    it 'saves when an ORCID with a non-numeric check digit is provided' do
      user.orcid = 'http://orcid.org/0000-0000-1111-222X'
      expect(user).to be_valid
      expect(user.save).to be true
    end
    it 'saves when a valid ORCID URI is supplied' do
      user.orcid = 'http://orcid.org/0000-0000-1111-2222'
      expect(user).to be_valid
      expect(user.save).to be true
    end
    it 'normalizes bare ORCIDs to URIs' do
      user.orcid = '0000-0000-1111-2222'
      user.save
      expect(user.orcid).to eq 'http://orcid.org/0000-0000-1111-2222'
    end
    it 'marks bad ORCIDs as invalid' do
      user.orcid = '000-000-111-222'
      expect(user).not_to be_valid
      expect(user.save).to be false
    end
  end

  describe "#to_param" do
    let(:user) { User.new(email: 'jilluser@example.com') }

    it "should override to_param to make keys more recognizable in redis (and useable within Rails URLs)" do
      expect(user.to_param).to eq("jilluser@example-dot-com")
    end
  end

  it "should have a cancan ability defined" do
    expect(user).to respond_to(:can?)
  end
  it "should not have any followers" do
    expect(user.followers_count).to eq(0)
    expect(another_user.follow_count).to eq(0)
  end
  describe "follow/unfollow" do
    let(:user) { FactoryGirl.create(:user) }
    let(:another_user) { FactoryGirl.create(:user) }
    before do
      user.follow(another_user)
    end

    it "should be able to follow another user" do
      expect(user).to be_following(another_user)
      expect(another_user).to_not be_following(user)
      expect(another_user).to be_followed_by(user)
      expect(user).to_not be_followed_by(another_user)
    end
    it "should be able to unfollow another user" do
      user.stop_following(another_user)
      expect(user).to_not be_following(another_user)
      expect(another_user).to_not be_followed_by(user)
    end
  end

  describe "trophy_works" do
    let(:user) { FactoryGirl.create(:user) }
    let(:work1) { Sufia::Works::GenericWork.create { |w| w.apply_depositor_metadata(user) } }
    let(:work2) { Sufia::Works::GenericWork.create { |w| w.apply_depositor_metadata(user) } }
    let(:work3) { Sufia::Works::GenericWork.create { |w| w.apply_depositor_metadata(user) } }
    let!(:trophy1) { user.trophies.create!(generic_work_id: work1.id) }
    let!(:trophy2) { user.trophies.create!(generic_work_id: work2.id) }
    let!(:trophy3) { user.trophies.create!(generic_work_id: work3.id) }

    it "should return a list of generic works" do
      expect(user.trophy_works).to eq [work1, work2, work3]
    end

  end

  describe "activity streams" do
    let(:now) { DateTime.now.to_i }
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
      @subject.can_receive_deposits_from << user
      @subject.can_make_deposits_for << another_user
      @subject.save!
    end
    it "can_receive_deposits_from" do
      expect(@subject.can_receive_deposits_from.to_a).to eq [user]
      expect(user.can_make_deposits_for.to_a).to eq [@subject]
    end
    it "can_make_deposits_for" do
      expect(@subject.can_make_deposits_for.to_a).to eq [another_user]
      expect(another_user.can_receive_deposits_from.to_a).to eq [@subject]
    end
  end
end
