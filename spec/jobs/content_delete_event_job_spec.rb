describe ContentDeleteEventJob do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }
  let(:mock_time) { Time.zone.at(1) }
  let(:event) do
    {
      action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has deleted object '#{curation_concern.id}'",
      timestamp: '1'
    }
  end

  before do
    another_user.follow(user)
    third_user.follow(user)
    allow(Time).to receive(:now).and_return(mock_time)
  end

  context 'with a FileSet' do
    let(:curation_concern) { create(:file_set, title: ['Hamlet'], user: user) }

    it "logs the event to the depositor's profile and followers' dashboards" do
      expect {
        described_class.perform_now(curation_concern.id, user)
      }.to change { user.profile_events.length }.by(1)
        .and change { another_user.events.length }.by(1)
        .and change { third_user.events.length }.by(1)
      expect(user.profile_events.first).to eq(event)
      expect(another_user.events.first).to eq(event)
      expect(third_user.events.first).to eq(event)
    end
  end

  context 'with a Work' do
    let(:curation_concern) { create(:generic_work, title: ['BethsMac'], user: user) }

    it "logs the event to the depositor's profile and followers' dashboards" do
      expect {
        described_class.perform_now(curation_concern.id, user)
      }.to change { user.profile_events.length }.by(1)
        .and change { another_user.events.length }.by(1)
        .and change { third_user.events.length }.by(1)
      expect(user.profile_events.first).to eq(event)
      expect(another_user.events.first).to eq(event)
      expect(third_user.events.first).to eq(event)
    end
  end
end
