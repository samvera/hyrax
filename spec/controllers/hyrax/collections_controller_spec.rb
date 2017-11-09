RSpec.describe Hyrax::CollectionsController do
  routes { Hyrax::Engine.routes }
  let(:user)  { create(:user) }
  let(:other) { build(:user) }

  let(:collection) do
    create_for_repository(:public_collection,
                          title: ["My collection"],
                          description: ["My incredibly detailed description of the collection"],
                          user: user)
  end

  let!(:asset1)         { create_for_repository(:work, title: ["First of the Assets"], user: user, member_of_collection_ids: [collection.id]) }
  let!(:asset2)         { create_for_repository(:work, title: ["Second of the Assets"], user: user, member_of_collection_ids: [collection.id]) }
  let!(:asset3)         { create_for_repository(:work, title: ["Third of the Assets"], user: user, member_of_collection_ids: [collection.id]) }
  let!(:unowned_asset)  { create_for_repository(:work, user: other) }

  let(:collection_attrs) do
    { title: ['My First Collection'], description: ["The Description\r\n\r\nand more"] }
  end

  describe "#show" do # public landing page
    context "when signed in" do
      let(:persister) { Valkyrie.config.metadata_adapter.persister }

      before do
        sign_in user
      end

      it "returns the collection and its members" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        get :show, params: { id: collection }
        expect(response).to be_successful
        expect(response).to render_template("layouts/hyrax/1_column")
        expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
        expect(assigns[:presenter].title).to match_array collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map { |asset| asset.id.to_s }
      end

      context "and searching" do
        it "returns some works" do
          # "/collections/4m90dv529?utf8=%E2%9C%93&cq=King+Louie&sort="
          get :show, params: { id: collection, cq: "Third" }
          expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
          expect(assigns[:member_docs].map(&:id)).to match_array [asset3.id.to_s]
        end
      end

      context 'when the page parameter is passed' do
        it 'loads the collection (paying no attention to the page param)' do
          get :show, params: { id: collection, page: '2' }
          expect(response).to be_successful
          expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
          expect(assigns[:presenter].to_s).to eq 'My collection'
        end
      end

      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          get :show, params: { id: collection }
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Your Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'))
          get :show, params: { id: collection }
          expect(response).to be_successful
        end
      end
    end

    context "not signed in" do
      it "does not show me files in the collection" do
        get :show, params: { id: collection }
        expect(assigns[:member_docs].count).to eq 0
      end
    end
  end
end
