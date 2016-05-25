describe ContentUpdateEventJob do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }
  let(:mock_time) { Time.zone.at(1) }

  before do
    another_user.follow(user)
    third_user.follow(user)
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  context "when the followers have access to view the FileSet" do
    let(:curation_concern) { create(:file_set, title: ['Hamlet'], user: user) }
    let(:event) do
      {
        action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has updated <a href=\"/concern/file_sets/#{curation_concern.id}\">Hamlet</a>",
        timestamp: '1'
      }
    end

    before do
      allow_any_instance_of(User).to receive(:can?).and_return(true)
    end

    it "logs the event to the depositor's profile, followers' dashboards, and the FileSet" do
      expect {
        described_class.perform_now(curation_concern, user)
      }.to change { user.profile_events.length }.by(1)
        .and change { another_user.events.length }.by(1)
        .and change { third_user.events.length }.by(1)
        .and change { curation_concern.events.length }.by(1)

      expect(user.profile_events.first).to eq(event)
      expect(another_user.events.first).to eq(event)
      expect(third_user.events.first).to eq(event)
      expect(curation_concern.events.first).to eq(event)
    end
  end

  context "when the followers have access to view the Work" do
    let(:curation_concern) { create(:work, title: ['BethsMac'], user: user) }
    let(:event) do
      {
        action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has updated <a href=\"/concern/generic_works/#{curation_concern.id}\">BethsMac</a>",
        timestamp: '1'
      }
    end

    before do
      allow_any_instance_of(User).to receive(:can?).and_return(true)
    end

    it "logs the event to the depositor's profile, followers' dashboards, and the Work" do
      expect {
        described_class.perform_now(curation_concern, user)
      }.to change { user.profile_events.length }.by(1)
        .and change { another_user.events.length }.by(1)
        .and change { third_user.events.length }.by(1)
        .and change { curation_concern.events.length }.by(1)

      expect(user.profile_events.first).to eq(event)
      expect(another_user.events.first).to eq(event)
      expect(third_user.events.first).to eq(event)
      expect(curation_concern.events.first).to eq(event)
    end
  end

  RSpec::Matchers.define_negated_matcher :does_not_change, :change

  context "when the followers lack access to the FileSet" do
    let(:file_set) { create(:file_set, title: ['Hamlet'], user: user) }
    let(:event) do
      {
        action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has updated <a href=\"/concern/file_sets/#{file_set.id}\">Hamlet</a>",
        timestamp: '1'
      }
    end

    it "does not log content-related jobs to followers" do
      expect {
        described_class.perform_now(file_set, user)
      }.to change { user.profile_events.length }.by(1)
        .and does_not_change { another_user.events.length }
        .and does_not_change { third_user.events.length }
        .and change { file_set.events.length }.by(1)

      expect(user.profile_events.first).to eq(event)
      expect(file_set.events.first).to eq(event)
    end
  end
end
