RSpec.describe "hyrax/dashboard/show_user.html.erb", type: :view do
  let(:user) { build(:user) }
  let(:ability) { instance_double("Ability") }
  before do
    allow(controller).to receive(:current_user).and_return(user)
    assign(:presenter, presenter)
  end
  let(:presenter) do
    instance_double(Hyrax::Dashboard::UserPresenter,
                    render_recent_activity: 'recent activity',
                    render_recent_notifications: 'recent notifications',
                    link_to_additional_notifications: 'additional notifications',
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
end
