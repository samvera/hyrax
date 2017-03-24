describe Hyrax::My::CollectionsController, type: :controller do
  describe "logged in user" do
    describe "#index" do
      let(:user) { create(:user) }
      let(:response) { instance_double(Blacklight::Solr::Response, response: { 'numFound' => 3 }) }
      let(:doc_list) { [double(id: 123), double(id: 456)] }
      before do
        sign_in user
      end

      it "shows the search results and sets breadcrumbs" do
        expect(controller).to receive(:search_results).with(ActionController::Parameters).and_return([response, doc_list])

        expect(controller).to receive(:add_breadcrumb).with('Home', root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Administration', dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Collections', my_collections_path(locale: 'en'))

        get :index, params: { per_page: 2 }
        expect(assigns[:document_list].length).to eq 2
      end
    end
  end

  describe "#search_facet_path" do
    subject { controller.send(:search_facet_path, id: 'keyword_sim') }
    it { is_expected.to eq "/dashboard/my/collections/facet/keyword_sim?locale=en" }
  end

  describe "#search_builder_class" do
    subject { controller.search_builder_class }
    it { is_expected.to eq Hyrax::MyCollectionsSearchBuilder }
  end
end
