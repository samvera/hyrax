describe Hyrax::My::CollectionsController, type: :controller do
  describe "logged in user" do
    describe "#index" do
      let(:user)  { create(:user) }
      let(:other) { create(:user) }
      before do
        sign_in user
        build(:public_collection, user: user, id: 1).update_index
        build(:public_collection, user: user, id: 2).update_index
        build(:public_collection, user: user, id: 3).update_index
        unrelated_collection.update_index
      end
      let(:unrelated_collection) { build(:public_collection, user: other, id: 4) }

      it "shows only collections I own and paginates the results" do
        get :index, params: { per_page: 2 }
        expect(assigns[:document_list].length).to eq 2
        expect(assigns[:document_list].map(&:id)).not_to include(unrelated_collection)
        get :index, params: { per_page: 2, page: 2 }
        expect(assigns[:document_list].length).to be >= 1
      end
    end

    describe "#search_facet_path" do
      subject { controller.send(:search_facet_path, id: 'keyword_sim') }
      it { is_expected.to eq "/dashboard/collections/facet/keyword_sim?locale=en" }
    end
  end
end
