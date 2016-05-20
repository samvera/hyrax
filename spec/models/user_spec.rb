require 'spec_helper'

describe User, type: :model do
  let(:user) { FactoryGirl.build(:user) }
  let(:another_user) { FactoryGirl.build(:user) }

  it "has an email" do
    expect(user.user_key).to be_kind_of String
  end
  it "has activity stream-related methods defined" do
    expect(user).to respond_to(:stream)
    expect(user).to respond_to(:events)
    expect(user).to respond_to(:profile_events)
    expect(user).to respond_to(:log_event)
    expect(user).to respond_to(:log_profile_event)
  end
  it "has social attributes" do
    expect(user).to respond_to(:twitter_handle)
    expect(user).to respond_to(:facebook_handle)
    expect(user).to respond_to(:googleplus_handle)
    expect(user).to respond_to(:linkedin_handle)
    expect(user).to respond_to(:orcid)
  end

  describe 'Arkivo and Zotero integration' do
    it 'sets an Arkivo token after_initialize if API is enabled' do
      expect(described_class.new).to respond_to(:arkivo_token)
    end

    describe 'Arkivo token generation' do
      before do
        allow(SecureRandom).to receive(:base64).with(24).and_return(token1, token1, token2)
      end

      let(:token1) { 'token1' }
      let(:token2) { 'token2' }

      it 'generates a new token if a user is found with the existing token' do
        user1 = described_class.create(email: 'foo@example.org', password: 'foobarbaz')
        expect(user1.arkivo_token).to eq token1
        user2 = described_class.create(email: 'bar@example.org', password: 'bazquuxquuux')
        expect(user2.arkivo_token).to eq token2
      end
    end

    describe 'Zotero tokens' do
      let(:token) { 'something' }

      it 'has a custom getter/setter for Zotero request tokens' do
        user.zotero_token = token
        expect(user.read_attribute(:zotero_token)).to eq Marshal.dump(token)
        expect(user.zotero_token).to eq token
      end
    end
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
    let(:user) { described_class.new(email: 'jilluser@example.com') }

    it "overrides to_param to make keys more recognizable in redis (and useable within Rails URLs)" do
      expect(user.to_param).to eq("jilluser@example-dot-com")
    end
  end

  subject { user }
  it { is_expected.to delegate_method(:can?).to(:ability) }
  it { is_expected.to delegate_method(:cannot?).to(:ability) }

  it "does not have any followers" do
    expect(user.followers_count).to eq(0)
    expect(another_user.follow_count).to eq(0)
  end
  describe "follow/unfollow" do
    let(:user) { FactoryGirl.create(:user) }
    let(:another_user) { FactoryGirl.create(:user) }
    before do
      user.follow(another_user)
    end

    it "is able to follow another user" do
      expect(user).to be_following(another_user)
      expect(another_user).to_not be_following(user)
      expect(another_user).to be_followed_by(user)
      expect(user).to_not be_followed_by(another_user)
    end
    it "is able to unfollow another user" do
      user.stop_following(another_user)
      expect(user).to_not be_following(another_user)
      expect(another_user).to_not be_followed_by(user)
    end
  end

  describe "trophy_works" do
    let(:user) { FactoryGirl.create(:user) }
    let(:work1) { GenericWork.create(title: ["work A"]) { |w| w.apply_depositor_metadata(user) } }
    let(:work2) { GenericWork.create(title: ["work B"]) { |w| w.apply_depositor_metadata(user) } }
    let(:work3) { GenericWork.create(title: ["work C"]) { |w| w.apply_depositor_metadata(user) } }
    let!(:trophy1) { user.trophies.create!(work_id: work1.id) }
    let!(:trophy2) { user.trophies.create!(work_id: work2.id) }
    let!(:trophy3) { user.trophies.create!(work_id: work3.id) }

    it "returns a list of generic works" do
      expect(user.trophy_works).to eq [work1, work2, work3]
    end
  end

  describe "activity streams" do
    let(:now) { Time.zone.now.to_i }
    let(:activities) {
      [{ action: 'so and so edited their profile', timestamp: now },
       { action: 'so and so uploaded a file', timestamp: (now - 360) }]
    }
    let(:file_activities) {
      [{ action: 'uploaded a file', timestamp: now + 1 }]
    }

    before do
      allow(user).to receive(:events).and_return(activities)
      allow(user).to receive(:profile_events).and_return(file_activities)
    end

    it "gathers the user's recent activity within the default amount of time" do
      expect(user.all_user_activity).to eq(file_activities.concat(activities))
    end

    it "gathers the user's recent activity within a given timestamp" do
      expect(user.all_user_activity(now - 60)).to eq(file_activities.concat([activities.first]))
    end
  end
  describe "proxy_deposit_rights" do
    before do
      @subject = create :user
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
  describe "class methods" do
    describe "recent_users" do
      let(:new_users) { described_class.all.order(created_at: :desc) }

      before do
        (1..3).each { |i| described_class.create(email: "abc#{i}@blah.frg", password: "blarg1234", created_at: Time.zone.now - i.days) }
      end

      context "when has a start date" do
        subject { described_class.recent_users(Time.zone.today - 2.days) }
        it "returns valid data" do
          expect(subject.count).to eq 2
          is_expected.to include(new_users[0], new_users[1])
          is_expected.not_to include(new_users[2])
        end
      end

      context "when has start and end date" do
        subject { described_class.recent_users(Time.zone.today - 2.days, Time.zone.today - 1.day) }
        it "returns valid data" do
          expect(subject.count).to eq 1
          is_expected.to include(new_users[1])
          is_expected.not_to include(new_users[2], new_users[0])
        end
      end
    end
  end
end
