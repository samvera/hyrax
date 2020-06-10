# frozen_string_literal: true
RSpec.describe "hyrax/dashboard/show_user.html.erb", type: :view do
  before do
    allow(controller).to receive(:current_user).and_return(user)
    assign(:presenter, presenter)
  end
  let(:user) { build(:user) }
  let(:ability) { instance_double("Ability") }
  let(:presenter) do
    instance_double(Hyrax::Dashboard::UserPresenter,
                    render_recent_activity: 'recent activity',
                    render_recent_notifications: 'recent notifications',
                    link_to_additional_notifications: 'additional notifications',
                    link_to_manage_proxies: 'Manage Proxies',
                    transfers: transfer_presenter)
  end
  let(:transfer_presenter) do
    instance_double(Hyrax::TransfersPresenter,
                    render_sent_transfers: 'sent transfers',
                    render_received_transfers: 'received transfers')
  end

  it "includes recent activities and notifications" do
    render
    expect(rendered).to have_content "User Activity"
    expect(rendered).to have_content "recent activity"

    expect(rendered).to have_content "User Notifications"
    expect(rendered).to have_content "recent notifications"
    expect(rendered).to have_content "additional notifications"

    expect(rendered).to have_content "Select works to transfer"
    expect(rendered).to have_content "sent transfers"
    expect(rendered).to have_content "received transfers"
  end

  describe 'proxy deposit' do
    context 'when enabled' do
      before do
        allow(Flipflop).to receive(:proxy_deposit?).and_return(true)
      end

      it 'renders proxy partial' do
        render
        expect(rendered).to match(/Current Proxies/)
        expect(rendered).to match(/Manage Proxies/)
      end
    end

    context 'when disabled' do
      before do
        allow(Flipflop).to receive(:proxy_deposit?).and_return(false)
      end

      it 'does not render proxy partial' do
        render
        expect(rendered).not_to match(/Current Proxies/)
        expect(rendered).not_to match(/Manage Proxies/)
      end
    end
  end
end
