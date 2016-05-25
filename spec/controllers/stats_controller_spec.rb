describe StatsController do
  let(:user) { create(:user) }
  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  routes { Sufia::Engine.routes }
  let(:usage) { double }

  describe '#file' do
    let(:file_set) { create(:file_set, user: user) }
    context 'when user has access to file' do
      before do
        sign_in user
      end

      it 'renders the stats view' do
        expect(FileUsage).to receive(:new).with(file_set.id).and_return(usage)
        allow(controller.request).to receive(:referer).and_return('foo')
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.works'), Sufia::Engine.routes.url_helpers.dashboard_works_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.file_set.browse_view'), Rails.application.routes.url_helpers.curation_concerns_file_set_path(file_set))
        get :file, id: file_set
        expect(response).to be_success
        expect(response).to render_template('stats/file')
      end
    end

    context "user is not signed in but the file is public" do
      let(:file_set) { create(:file_set, :public, user: user) }

      it 'renders the stats view' do
        get :file, id: file_set
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
        get :file, id: file_set
        expect(response).to redirect_to(Sufia::Engine.routes.url_helpers.root_path)
      end
    end
  end

  describe 'work' do
    let(:work) { create(:generic_work, user: user) }
    before do
      sign_in user
      allow(controller.request).to receive(:referer).and_return('foo')
    end

    it 'renders the stats view' do
      expect(WorkUsage).to receive(:new).with(work.id).and_return(usage)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.works'), Sufia::Engine.routes.url_helpers.dashboard_works_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.work.browse_view'), curation_concerns_generic_work_path(work))
      get :work, id: work
      expect(response).to be_success
      expect(response).to render_template('stats/work')
    end
  end
end
