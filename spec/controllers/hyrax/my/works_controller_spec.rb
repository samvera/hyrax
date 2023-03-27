# frozen_string_literal: true
RSpec.describe Hyrax::My::WorksController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "#index" do
    let(:response) { instance_double(Blacklight::Solr::Response, response: { 'numFound' => 3 }) }
    let(:doc_list) { [double(id: 123), double(id: 456)] }
    let(:my_collection) { instance_double(SolrDocument) }
    let(:collection_service) { instance_double(Hyrax::CollectionsService) }

    before do
      allow(Hyrax::CollectionsService).to receive(:new).and_return(collection_service)
      allow(Hyrax::Works::ManagedWorksService).to receive(:managed_works_count).and_return(1)
    end

    it "shows search results and breadcrumbs" do
      expect_any_instance_of(Hyrax::SearchService).to receive(:search_results).and_return([response, doc_list])
      expect(controller).to receive(:add_breadcrumb).with('Home', root_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with('Works', my_works_path(locale: 'en'))
      expect(collection_service).to receive(:search_results).with(:deposit).and_return([my_collection])
      get :index, params: { per_page: 2 }
      expect(assigns[:document_list].length).to eq 2
      expect(assigns[:user_collections]).to contain_exactly(my_collection)
      expect(assigns[:managed_works_count]).to eq 1
    end
  end

  describe "#search_builder_class" do
    subject { controller.blacklight_config.search_builder_class }

    it { is_expected.to eq Hyrax::My::WorksSearchBuilder }
  end

  describe "#collections_service" do
    subject { controller.send(:collections_service) }

    it { is_expected.to be_an_instance_of Hyrax::CollectionsService }
  end

  context "when add_works_to_collection is provided" do
    it "sets add_works_to_collection ivar" do
      get :index, params: { add_works_to_collection: '12345' }
      expect(assigns(:add_works_to_collection)).to eql('12345')
    end
  end

  describe "#search_facet_path" do
    subject { controller.send(:search_facet_path, id: 'keyword_sim') }

    it { is_expected.to eq "/dashboard/my/works/facet/keyword_sim?locale=en" }
  end
end
