# frozen_string_literal: true
RSpec.describe '/_user_util_links.html.erb', type: :view do
  let(:join_date) { 5.days.ago }
  let(:can_create_file) { true }
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }

  context 'signed in' do
    before do
      allow(view).to receive(:user_signed_in?).and_return(true)
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:can?).with(:create, GenericWork).and_return(can_create_file)
    end

    context 'partial elements' do
      it 'has dropdown list of links' do
        render
        expect(rendered).to have_link user.user_key, href: '#', id: 'navbarDropdown'
        expect(rendered).to have_link 'My Profile', href: hyrax.dashboard_profile_path(user)
        expect(rendered).to have_link 'Dashboard', href: hyrax.dashboard_path
        # expect(rendered).to have_button 'Logout'
        # expect(rendered).to have_field '_method', type: :hidden, with: Devise.sign_out_via
      end

      it 'shows zero outstanding messages' do
        render
        expect(rendered).to have_selector "a[aria-description='You have no unread notifications'][href='#{hyrax.notifications_path}']"
        expect(rendered).to have_selector 'a.notify-number.nav-link span.count.badge.invisible.badge-secondary', text: '0'
      end

      context 'with pending notifications' do
        it 'shows the number of outstanding messages' do
          2.times { other_user.send_message(user, 'Test', 'Test message') }
          render
          expect(rendered).to have_selector "a[aria-description='You have 2 unread notifications'][href='#{hyrax.notifications_path}']"
          expect(rendered).to have_selector 'a.notify-number.nav-link span.count.badge.badge-danger', text: '2'
        end
      end
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

  context 'not signed in' do
    before do
      allow(view).to receive(:user_signed_in?).and_return(false)
    end

    describe 'authentication links' do
      before { render }

      it 'displays a login link' do
        expect(rendered).to have_link('Login')
      end
    end
  end
end
