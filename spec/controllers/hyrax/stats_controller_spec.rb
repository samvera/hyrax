# frozen_string_literal: true
RSpec.describe Hyrax::StatsController do
  let(:user) { create(:user) }
  let(:usage) { double(to_flot: []) }

  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  routes { Hyrax::Engine.routes }

  shared_context('with user signed in and http referer set') do
    before do
      sign_in user
      request.env['HTTP_REFERER'] = 'http://test.host/foo'
    end
  end

  def test_loading_file_set_with_user_access # rubocop:disable Metrics/AbcSize
    expect(Hyrax::FileUsage).to receive(:new).with(file_set.id).and_return(usage)
    expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
    expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
    expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
    expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.file_set.browse_view'), Rails.application.routes.url_helpers.hyrax_file_set_path(file_set, locale: 'en'))
    get :file, params: { id: file_set }
    expect(response).to be_successful
    expect(response).to render_template('stats/file')
  end # rubocop:enable Metrics/AbcSize

  def test_loading_public_file_no_user_signed_in
    get :file, params: { id: file_set }
    expect(response).to be_successful
    expect(response).to render_template('stats/file')
  end

  def test_loading_file_user_no_access_signed_in
    get :file, params: { id: file_set }
    expect(response).to redirect_to(Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
  end

  context 'with ActiveFedora objects', :active_fedora do
    describe '#file' do
      let(:file_set) { create(:file_set, user: user) }

      context 'when user has access to file' do
        include_context 'with user signed in and http referer set'

        it 'renders the stats view' do
          test_loading_file_set_with_user_access
        end
      end

      context "user is not signed in but the file is public" do
        let(:file_set) { create(:file_set, :public, user: user) }

        it 'renders the stats view' do
          test_loading_public_file_no_user_signed_in
        end
      end

      context 'when user lacks access to file' do
        let(:file_set) { create(:file_set) }

        before { sign_in user }

        it 'redirects to root_url' do
          test_loading_file_user_no_access_signed_in
        end
      end
    end

    describe 'work' do
      let(:work) { create(:generic_work, user: user) }

      include_context 'with user signed in and http referer set'

      it 'renders the stats view' do
        expect(Hyrax::Analytics).to receive(:daily_events_for_id).with(work.id, 'work-view').and_return([])
        expect(Hyrax::Analytics).to receive(:daily_events_for_id).with(work.id, 'file-set-in-work-download').and_return([])
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Test title', main_app.hyrax_generic_work_path(work, locale: 'en'))
        get :work, params: { id: work }
        expect(response).to be_successful
        expect(response).to render_template('stats/work')
      end
    end
  end

  context 'when Google Analytics raises an error' do
    let(:denied) { Google::Cloud::PermissionDeniedError.new('User does not have sufficient permissions for this property.') }

    render_views

    include_context 'with user signed in and http referer set'

    describe '#file' do
      let(:file_set) { valkyrie_create(:hyrax_file_set, depositor: user.user_key, edit_users: [user.user_key], date_uploaded: 3.days.ago) }

      before { allow(Hyrax::Analytics).to receive(:page_statistics).and_raise(denied) }

      it 'renders the stats view with zeroed data and an analytics notice' do
        get :file, params: { id: file_set }
        expect(response).to be_successful
        expect(response).to render_template('stats/file')
        expect(assigns(:analytics_error)).to be_present
        expect(response.body).to include(I18n.t('hyrax.admin.analytics.errors.permission.message'))
        expect(assigns(:stats).total_pageviews).to eq 0
        expect(assigns(:stats).total_downloads).to eq 0
      end
    end

    describe '#work' do
      let(:work) { valkyrie_create(:monograph, depositor: user.user_key, edit_users: [user.user_key]) }

      before { allow(Hyrax::Analytics).to receive(:daily_events_for_id).and_raise(denied) }

      it 'renders the stats view with zeroed data and an analytics notice' do
        get :work, params: { id: work }
        expect(response).to be_successful
        expect(response).to render_template('stats/work')
        expect(assigns(:analytics_error)).to be_present
        expect(response.body).to include(I18n.t('hyrax.admin.analytics.errors.permission.message'))
        expect(assigns(:pageviews).all).to eq 0
        expect(assigns(:downloads).all).to eq 0
      end

      context 'with a non-permission Google error' do
        let(:denied) { Google::Cloud::InvalidArgumentError.new('Invalid property') }

        it 'renders the stats view with the general notice' do
          get :work, params: { id: work }
          expect(response).to be_successful
          expect(response.body).to include(CGI.escapeHTML(I18n.t('hyrax.admin.analytics.errors.general.message')))
        end
      end
    end
  end

  # NOTE: The tests below do not function as expected due to the classes involving Stats not being Valkyrized.
  #   See spec/presenters/hyrax/file_usage_spec.rb for an example.
  context 'with Valkyrie objects' do
    describe '#file' do
      let(:file_set) { valkyrie_create(:hyrax_file_set, depositor: user.user_key) }

      context 'when user has access to file' do
        include_context 'with user signed in and http referer set'

        xit 'renders the stats view' do
          test_loading_file_set_with_user_access
        end
      end

      context "user is not signed in but the file is public" do
        let(:file_set) { valkyrie_create(:hyrax_file_set, :public, depositor: user.user_key) }

        xit 'renders the stats view' do
          test_loading_public_file_no_user_signed_in
        end
      end

      context 'when user lacks access to file' do
        let(:file_set) { valkyrie_create(:hyrax_file_set) }

        before { sign_in user }

        xit 'redirects to root_url' do
          test_loading_file_user_no_access_signed_in
        end
      end
    end

    describe 'work' do
      let(:work) { valkyrie_create(:monograph, depositor: user.user_key) }

      include_context 'with user signed in and http referer set'

      xit 'renders the stats view' do
        expect(Hyrax::Analytics).to receive(:daily_events_for_id).with(work.id, 'work-view').and_return([])
        expect(Hyrax::Analytics).to receive(:daily_events_for_id).with(work.id, 'file-set-in-work-download').and_return([])
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Test title', main_app.hyrax_monograph_path(work, locale: 'en'))
        get :work, params: { id: work }
        expect(response).to be_successful
        expect(response).to render_template('stats/work')
      end
    end
  end
end
