require 'spec_helper'

describe StatsController do
  let(:user) { create(:user) }
  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  describe 'file' do
    routes { Sufia::Engine.routes }

    let(:file_set) do
      FileSet.create do |fs|
        fs.apply_depositor_metadata(user)
      end
    end

    context 'when user has access to file' do
      before do
        sign_in user
        file_set_query = double('query')
        allow(file_set_query).to receive(:for_path).and_return([
          OpenStruct.new(date: '2014-01-01', pageviews: 4),
          OpenStruct.new(date: '2014-01-02', pageviews: 8),
          OpenStruct.new(date: '2014-01-03', pageviews: 6),
          OpenStruct.new(date: '2014-01-04', pageviews: 10),
          OpenStruct.new(date: '2014-01-05', pageviews: 2)])
        allow(file_set_query).to receive(:map).and_return(file_set_query.for_path.map(&:marshal_dump))
        profile = double('profile')
        allow(profile).to receive(:sufia__pageview).and_return(file_set_query)
        allow(Sufia::Analytics).to receive(:profile).and_return(profile)

        download_query = double('query')
        allow(download_query).to receive(:for_file).and_return([
          OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "123456789", totalEvents: "3")
        ])
        allow(download_query).to receive(:map).and_return(download_query.for_file.map(&:marshal_dump))
        allow(profile).to receive(:sufia__download).and_return(download_query)
      end

      it 'renders the stats view' do
        allow(controller.request).to receive(:referer).and_return('foo')
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.works'), Sufia::Engine.routes.url_helpers.dashboard_works_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.file_set.browse_view'), Rails.application.routes.url_helpers.curation_concerns_file_set_path(file_set))
        get :file, id: file_set
        expect(response).to be_success
        expect(response).to render_template('stats/file')
      end

      context "user is not signed in but the file is public" do
        before do
          file_set.read_groups = ['public']
          file_set.save
        end

        it 'renders the stats view' do
          get :file, id: file_set
          expect(response).to be_success
          expect(response).to render_template('stats/file')
        end
      end
    end

    context 'when user lacks access to file' do
      before do
        sign_in FactoryGirl.create(:user)
      end

      it 'redirects to root_url' do
        get :file, id: file_set
        expect(response).to redirect_to(Sufia::Engine.routes.url_helpers.root_path)
      end
    end
  end
end
