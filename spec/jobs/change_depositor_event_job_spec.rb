# frozen_string_literal: true
RSpec.describe ChangeDepositorEventJob do
  let(:previous_user) { create(:user) }
  let(:new_user) { create(:user) }
  let(:mock_time) { Time.zone.at(1) }
  let(:event) do
    { action:
        "User <a href=\"/users/#{previous_user.to_param}\">#{previous_user.user_key}</a> " \
        "has transferred <a href=\"/concern/generic_works/#{generic_work.id}\">BethsMac</a> " \
        "to user <a href=\"/users/#{new_user.to_param}\">#{new_user.user_key}</a>",
      timestamp: '1' }
  end

  before do
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  context "when passing an ActiveFedora work", :active_fedora do
    let(:generic_work) { create(:generic_work, title: ['BethsMac'], user: new_user, proxy_depositor: previous_user.user_key) }

    it "logs the event to the proxy depositor's profile, the depositor's dashboard, and the FileSet" do
      expect { described_class.perform_now(generic_work) }
        .to change { previous_user.profile_events.length }
        .by(1)
        .and change { new_user.events.length }
        .by(1)
        .and change { generic_work.events.length }
        .by(1)
      expect(previous_user.profile_events.first).to eq(event)
      expect(new_user.events.first).to eq(event)
      expect(generic_work.events.first).to eq(event)
    end
  end

  context "when passing a valkyrie work" do
    let(:monograph) { valkyrie_create(:monograph, title: ['BethsMac'], depositor: new_user.user_key, proxy_depositor: previous_user.user_key) }

    let(:event) do
      { action: "User <a href=\"/users/#{previous_user.to_param}\">#{previous_user.user_key}</a> " \
                "has transferred <a href=\"/concern/monographs/#{monograph.id}\">BethsMac</a> " \
                "to user <a href=\"/users/#{new_user.to_param}\">#{new_user.user_key}</a>",
        timestamp: '1' }
    end

    it "logs the event to the proxy depositor's profile, the depositor's dashboard, and the FileSet" do
      expect { subject.perform(monograph) }
        .to change { previous_user.profile_events.length }
        .by(1)
        .and change { new_user.events.length }
        .by(1)
        .and change { monograph.events.length }
        .by(1)
      expect(previous_user.profile_events.first).to eq(event)
      expect(new_user.events.first).to eq(event)
      expect(monograph.events.first).to eq(event)
    end
  end
end
