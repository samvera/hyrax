# frozen_string_literal: true
RSpec.describe ContentDeleteEventJob do
  let(:user) { create(:user) }
  let(:mock_time) { Time.zone.at(1) }
  let(:event) do
    {
      action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has deleted object '#{curation_concern.id}'",
      timestamp: '1'
    }
  end

  before do
    allow(Time).to receive(:now).and_return(mock_time)
  end

  context 'with a FileSet' do
    let(:curation_concern) { valkyrie_create(:hyrax_file_set, title: ['Hamlet'], depositor: user.user_key) }

    it "logs the event to the depositor's profile" do
      expect do
        described_class.perform_now(curation_concern.id, user)
      end.to change { user.profile_events.length }.by(1)
      expect(user.profile_events.first).to eq(event)
    end
  end

  context 'with a Work' do
    let(:curation_concern) { valkyrie_create(:hyrax_work, title: ['BethsMac'], depositor: user.user_key) }

    it "logs the event to the depositor's profile" do
      expect do
        described_class.perform_now(curation_concern.id, user)
      end.to change { user.profile_events.length }.by(1)
      expect(user.profile_events.first).to eq(event)
    end
  end
end
