# frozen_string_literal: true
RSpec.describe ContentNewVersionEventJob do
  let(:user) { create(:user) }
  let(:file_set) { valkyrie_create(:hyrax_file_set, title: ['Hamlet'], depositor: user.user_key) }
  let(:mock_time) { Time.zone.at(1) }
  let(:event) { { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has added a new version of <a href=\"/concern/file_sets/#{file_set.id}\">Hamlet</a>", timestamp: '1' } }

  before do
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  it "logs the event to the depositor's profile and the FileSet" do
    expect do
      described_class.perform_now(file_set, user)
    end.to change { user.profile_events.length }.by(1)
                                                .and change { file_set.events.length }.by(1)

    expect(user.profile_events.first).to eq(event)
    expect(file_set.events.first).to eq(event)
  end
end
