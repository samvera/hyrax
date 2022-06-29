# frozen_string_literal: true
RSpec.describe User, type: :model do
  let(:user) { build(:user) }
  let(:another_user) { build(:user) }

  describe 'verifying factories' do
    describe ':user' do
      let(:user) { build(:user) }

      it 'will, by default, have no groups' do
        expect(user.groups).to eq([])
        user.save!
        # Ensuring that we can refind it and have the correct groups
        expect(user.class.find(user.id).groups).to eq([])
      end
      it 'will allow for override of groups' do
        user = build(:user, groups: 'chicken')
        expect(user.groups).to eq(['chicken'])
        user.save!
        # Ensuring that we can refind it and have the correct groups
        expect(user.class.find(user.id).groups).to eq(['chicken'])
      end
    end
    describe ':admin' do
      let(:admin_user) { create(:admin) }

      it 'will have an "admin" group' do
        expect(admin_user.groups).to eq(['admin'])
      end
      context 'when found from the database' do
        it 'will have the expected "admin" group' do
          refound_admin_user = described_class.find(admin_user.id)
          expect(refound_admin_user.groups).to eq(['admin'])
        end
      end
    end
  end

  describe '#user_key' do
    it 'is email by default' do
      expect(user.user_key).to eq user.email
    end

    context 'with a custom user_key_field' do
      let(:user)  { build(:user, display_name: value) }
      let(:value) { 'moomin' }

      before do
        allow(Hydra.config).to receive(:user_key_field).and_return(:display_name)
      end

      it 'is email by default' do
        expect(user.user_key).to eq value
      end

      it 'is findable by user_key' do
        user.save

        expect(described_class.find_by_user_key(value)).to eq user
      end
    end
  end

  describe '#agent_key' do
    let(:key) { user.agent_key }

    it 'is the same as the user key' do
      expect(key).to eq user.user_key
    end

    it 'is findable by agent_key' do
      user.save!

      expect(described_class.from_agent_key(key)).to eq user
    end
  end

  it "has an email" do
    expect(user.email).to be_kind_of String
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
    it 'saves when a valid ORCID HTTP URI w/ trailing slash is supplied' do
      user.orcid = 'http://orcid.org/0000-0000-1111-2222/'
      expect(user).to be_valid
      expect(user.save).to be true
    end
    it 'saves when a valid ORCID HTTPS URI is supplied' do
      user.orcid = 'https://orcid.org/0000-0000-1111-2222'
      expect(user).to be_valid
      expect(user.save).to be true
    end
    it 'normalizes bare ORCIDs to HTTPS URIs' do
      user.orcid = '0000-0000-1111-2222'
      user.save
      expect(user.orcid).to eq 'https://orcid.org/0000-0000-1111-2222'
    end
    it 'normalizes HTTP ORCIDs to HTTPS URIs' do
      user.orcid = 'http://orcid.org/0000-0000-1111-2222'
      user.save
      expect(user.orcid).to eq 'https://orcid.org/0000-0000-1111-2222'
    end
    it 'marks short ORCIDs as invalid' do
      user.orcid = '000-000-111-222'
      expect(user).not_to be_valid
      expect(user.save).to be false
    end
    it 'marks long ORCIDs as invalid' do
      user.orcid = '0000-0000-1111-222222'
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

  describe '#to_sipity_agent' do
    subject { user.to_sipity_agent }

    it 'will find or create a Sipity::Agent' do
      user.save!
      expect { subject }.to change { Sipity::Agent.count }.by(1)
    end

    it 'will fail if the User is not persisted' do
      expect { subject }.to raise_error(ActiveRecord::RecordNotSaved)
    end

    context "when another process makes the agent" do
      let(:user) { create(:user) }

      before do
        user.sipity_agent # load up and cache the association
        described_class.find(user.id).create_sipity_agent!
      end
      it "returns the existing agent" do
        expect { subject }.not_to change { Sipity::Agent.count }
      end
    end
  end

  describe "activity streams" do
    let(:now) { Time.zone.now.to_i }
    let(:activities) do
      [{ action: 'so and so edited their profile', timestamp: now },
       { action: 'so and so uploaded a file', timestamp: (now - 360) }]
    end
    let(:file_activities) do
      [{ action: 'uploaded a file', timestamp: now + 1 }]
    end

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
    subject { create :user }

    before do
      subject.can_receive_deposits_from << user
      subject.can_make_deposits_for << another_user
      subject.save!
    end
    it "can_receive_deposits_from" do
      expect(subject.can_receive_deposits_from.to_a).to eq [user]
      expect(user.can_make_deposits_for.to_a).to eq [subject]
    end
    it "can_make_deposits_for" do
      expect(subject.can_make_deposits_for.to_a).to eq [another_user]
      expect(another_user.can_receive_deposits_from.to_a).to eq [subject]
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
  describe "scope Users" do
    let!(:basic_user) { create(:user) }
    let!(:guest_user) { create(:user, :guest) }
    let!(:system_user) { described_class.system_user }
    let!(:audit_user) { described_class.audit_user }
    let!(:batch_user) { described_class.batch_user }

    context "without_system_accounts" do
      subject { described_class.without_system_accounts }

      it "omits system_user, audit_user, and batch_user" do
        is_expected.to include(basic_user, guest_user)
        is_expected.not_to include(system_user, audit_user, batch_user)
      end
    end
    context "registered" do
      subject { described_class.registered }

      it "omits guest_user" do
        is_expected.to include(basic_user, system_user, audit_user, batch_user)
        is_expected.not_to include(guest_user)
      end
    end
    context "guests" do
      subject { described_class.guests }

      it "includes only guest_user" do
        is_expected.not_to include(basic_user, system_user, audit_user, batch_user)
        is_expected.to include(guest_user)
      end
    end
  end
end
