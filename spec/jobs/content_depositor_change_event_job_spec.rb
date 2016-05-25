describe ContentDepositorChangeEventJob do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }
  let(:generic_work) { create(:generic_work, title: ['BethsMac'], user: user) }
  let(:mock_time) { Time.zone.at(1) }
  let(:event) { { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> has transferred <a href=\"/concern/generic_works/#{generic_work.id}\">BethsMac</a> to user <a href=\"/users/#{another_user.to_param}\">#{another_user.user_key}</a>", timestamp: '1' } }
  before do
    third_user.follow(another_user)
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  it "logs the event to the proxy depositor's profile, the depositor's dashboard, followers' dashboards, and the FileSet" do
    expect {
      described_class.perform_now(generic_work, another_user)
    }.to change { user.profile_events.length }.by(1)
      .and change { another_user.events.length }.by(1)
      .and change { third_user.events.length }.by(1)
      .and change { generic_work.events.length }.by(1)

    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.first).to eq(event)
    expect(third_user.events.first).to eq(event)
    expect(generic_work.events.first).to eq(event)
  end
end
