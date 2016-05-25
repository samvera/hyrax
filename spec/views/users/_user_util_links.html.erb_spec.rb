describe '/_user_util_links.html.erb', type: :view do
  let(:join_date) { 5.days.ago }
  before do
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(stub_model(User, user_key: 'userX'))
    allow(view).to receive(:can?).with(:create, GenericWork).and_return(can_create_file)
    assign :notify_number, 8
  end

  let(:can_create_file) { true }

  it 'has link to user profile' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_link 'userX', href: '/users/userX'
  end

  it 'shows the number of outstanding messages' do
    render
    expect(rendered).to have_link 'Notifications 0 unread notifications', sufia.notifications_path
    expect(rendered).to have_selector '.label-default', text: '0 unread notifications'
  end
end
