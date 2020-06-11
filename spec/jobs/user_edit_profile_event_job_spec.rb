# frozen_string_literal: true
RSpec.describe UserEditProfileEventJob do
  let(:user) { create(:user) }
  let(:mock_time) { Time.zone.at(1) }
  let(:event) { { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has edited their profile", timestamp: '1' } }

  before do
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  it "logs the event to the editor's dashboards" do
    expect do
      described_class.perform_now(user)
    end.to change { user.events.length }.by(1)

    expect(user.events.first).to eq(event)
  end
end
