
describe Hyrax::My::WorksController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "#index" do
    let(:response) { instance_double(Blacklight::Solr::Response, response: { 'numFound' => 3 }) }
    let(:doc_list) { [double(id: 123), double(id: 456)] }
    let(:my_collection) { instance_double(SolrDocument) }
    let(:collection_service) { instance_double(Hyrax::CollectionsService) }
    before do
      allow(Hyrax::CollectionsService).to receive(:new).and_return(collection_service)
    end
    it "shows search results and breadcrumbs" do
      expect(controller).to receive(:search_results).with(ActionController::Parameters).and_return([response, doc_list])
      expect(controller).to receive(:add_breadcrumb).with('Home', root_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with('Administration', dashboard_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with('Works', my_works_path(locale: 'en'))
      expect(collection_service).to receive(:search_results).with(:edit).and_return([my_collection])
      get :index, params: { per_page: 2 }
      expect(assigns[:document_list].length).to eq 2
      expect(assigns[:user_collections]).to contain_exactly(my_collection)
    end
  end

  describe "#search_builder_class" do
    subject { controller.search_builder_class }
    it { is_expected.to eq Hyrax::MyWorksSearchBuilder }
  end

  describe "#collections_service" do
    subject { controller.send(:collections_service) }
    it { is_expected.to be_an_instance_of Hyrax::CollectionsService }
  end

  context "when add_files_to_collection is provided" do
    it "sets add_files_to_collection ivar" do
      get :index, params: { add_files_to_collection: '12345' }
      expect(assigns(:add_files_to_collection)).to eql('12345')
    end
  end

  describe "#search_facet_path" do
    subject { controller.send(:search_facet_path, id: 'keyword_sim') }
    it { is_expected.to eq "/dashboard/my/works/facet/keyword_sim?locale=en" }
  end
end
