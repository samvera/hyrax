RSpec.describe '/_user_util_links.html.erb', type: :view do
  let(:join_date) { 5.days.ago }
  before do
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(stub_model(User, user_key: 'userX'))
    allow(view).to receive(:can?).with(:create, GenericWork).and_return(can_create_file)
    assign :notify_number, 8
  end

  let(:can_create_file) { true }

  it 'has dropdown list of links' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_link 'userX', href: hyrax.dashboard_profile_path('userX')
    expect(rendered).to have_link 'Dashboard', href: hyrax.dashboard_path
  end

  it 'shows the number of outstanding messages' do
    render
    expect(rendered).to have_selector "a[aria-label='You have no unread notifications'][href='#{hyrax.notifications_path}']"
    expect(rendered).to have_selector 'a.notify-number span.label-danger.invisible', text: '0'
  end

  describe 'translations' do
    context 'with two languages' do
      before do
        allow(view).to receive(:available_translations) { { 'en' => 'English', 'es' => 'Español' } }
        render
      end
      it 'displays the current language' do
        expect(rendered).to have_link('English')
      end
    end
    context 'with one language' do
      before do
        allow(view).to receive(:available_translations) { { 'en' => 'English' } }
        render
      end
      it 'does not display the language picker' do
        expect(rendered).not_to have_link('English')
      end
    end
  end
end
