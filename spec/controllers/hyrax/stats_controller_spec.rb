describe Hyrax::StatsController do
  let(:user) { create(:user) }
  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  routes { Hyrax::Engine.routes }
  let(:usage) { double }

  describe '#file' do
    let(:file_set) { create(:file_set, user: user) }
    context 'when user has access to file' do
      before do
        sign_in user
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it 'renders the stats view' do
        expect(Hyrax::FileUsage).to receive(:new).with(file_set.id).and_return(usage)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.file_set.browse_view'), Rails.application.routes.url_helpers.hyrax_file_set_path(file_set, locale: 'en'))
        get :file, params: { id: file_set }
        expect(response).to be_success
        expect(response).to render_template('stats/file')
      end
    end

    context "user is not signed in but the file is public" do
      let(:file_set) { create(:file_set, :public, user: user) }

      it 'renders the stats view' do
        get :file, params: { id: file_set }
        expect(response).to be_success
        expect(response).to render_template('stats/file')
      end
    end

    context 'when user lacks access to file' do
      let(:file_set) { create(:file_set) }
      before do
        sign_in user
      end

      it 'redirects to root_url' do
        get :file, params: { id: file_set }
        expect(response).to redirect_to(Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
      end
    end
  end

  describe 'work' do
    let(:work) { create(:generic_work, user: user) }
    before do
      sign_in user
      request.env['HTTP_REFERER'] = 'http://test.host/foo'
    end

    it 'renders the stats view' do
      expect(Hyrax::WorkUsage).to receive(:new).with(work.id).and_return(usage)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with('Test title', main_app.hyrax_generic_work_path(work, locale: 'en'))
      get :work, params: { id: work }
      expect(response).to be_success
      expect(response).to render_template('stats/work')
    end
  end
end
