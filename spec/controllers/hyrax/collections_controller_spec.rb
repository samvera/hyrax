describe Hyrax::CollectionsController do
  routes { Hyrax::Engine.routes }
  before { allow_any_instance_of(User).to receive(:groups).and_return([]) }

  let(:user)  { create(:user) }
  let(:other) { create(:user) }

  let(:collection) do
    create(:public_collection, title: ["My collection"],
                               description: ["My incredibly detailed description of the collection"],
                               user: user)
  end

  let(:asset1)         { create(:work, title: ["First of the Assets"], user: user) }
  let(:asset2)         { create(:work, title: ["Second of the Assets"], user: user) }
  let(:asset3)         { create(:work, title: ["Third of the Assets"], user: user) }
  let(:unowned_asset)  { create(:work, user: other) }

  let(:collection_attrs) do
    { title: ['My First Collection'], description: ["The Description\r\n\r\nand more"] }
  end

  describe '#new' do
    before { sign_in user }

    it 'assigns @collection' do
      get :new
      expect(assigns(:collection)).to be_kind_of(Collection)
    end
  end

  describe '#create' do
    before { sign_in user }

    it "creates a Collection" do
      expect do
        post :create, params: {
          collection: collection_attrs.merge(visibility: 'open')
        }
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].visibility).to eq 'open'
    end

    it "removes blank strings from params before creating Collection" do
      expect do
        post :create, params: {
          collection: collection_attrs.merge(creator: [''])
        }
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].title).to eq ["My First Collection"]
      expect(assigns[:collection].creator).to eq []
    end

    context "with files I can access" do
      it "creates a collection using only the accessible files" do
        expect do
          post :create, params: {
            collection: collection_attrs,
            batch_document_ids: [asset1.id, asset2.id, unowned_asset.id]
          }
        end.to change { Collection.count }.by(1)
        collection = assigns(:collection)
        expect(collection.member_objects).to match_array [asset1, asset2]
      end

      it "adds docs to the collection and adds the collection id to the documents in the collection" do
        post :create, params: {
          batch_document_ids: [asset1.id],
          collection: collection_attrs
        }

        expect(assigns[:collection].member_objects).to eq [asset1]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params: { fq: ["id:\"#{asset1.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq asset1.id
      end
    end
  end

  describe '#index' do
    let!(:collection1) { create(:collection, :public, title: ['Beta']) }
    let!(:collection2) { create(:collection, :public, title: ['Alpha']) }
    let!(:generic_work) { create(:generic_work, :public) }

    it 'shows a list of collections sorted alphabetically' do
      get :index
      expect(response).to be_successful
      expect(assigns[:document_list].map(&:id)).not_to include generic_work.id
      expect(assigns[:document_list].map(&:id)).to match_array [collection2.id, collection1.id]
    end
  end

  describe "#update" do
    before { sign_in user }

    context 'collection members' do
      before do
        [asset1, asset2].each do |asset|
          asset.member_of_collections << collection
          asset.save!
        end
      end

      it "adds members to the collection" do
        expect do
          put :update, params: { id: collection,
                                 collection: { members: 'add' },
                                 batch_document_ids: [asset3.id] }
        end.to change { collection.reload.member_objects.size }.by(1)
        expect(response).to redirect_to routes.url_helpers.collection_path(collection, locale: 'en')
        expect(assigns[:collection].member_objects).to match_array [asset1, asset2, asset3]
      end

      it "removes members from the collection" do
        # TODO: Using size until count is fixed https://github.com/projecthydra-labs/activefedora-aggregation/issues/78
        expect do
          put :update, params: { id: collection,
                                 collection: { members: 'remove' },
                                 batch_document_ids: [asset2] }
        end.to change { asset2.reload.member_of_collections.size }.by(-1)
        expect(assigns[:collection].member_objects).to match_array [asset1]
      end
    end

    context 'when moving members between collections' do
      let(:asset1) { create(:generic_work, user: user) }
      let(:asset2) { create(:generic_work, user: user) }
      let(:asset3) { create(:generic_work, user: user) }
      let(:collection2) do
        Collection.create(title: ['Some Collection']) do |col|
          col.apply_depositor_metadata(user.user_key)
        end
      end
      before do
        [asset1, asset2, asset3].each do |asset|
          asset.member_of_collections << collection
          asset.save
        end
      end

      it 'moves the members' do
        put :update,
            params: {
              id: collection,
              collection: { members: 'move' },
              destination_collection_id: collection2,
              batch_document_ids: [asset2, asset3]
            }
        expect(collection.reload.member_objects).to eq [asset1]
        expect(collection2.reload.member_objects).to match_array [asset2, asset3]
      end
    end

    context "updating a collections metadata" do
      it "saves the metadata" do
        put :update, params: { id: collection, collection: { creator: ['Emily'] } }
        collection.reload
        expect(collection.creator).to eq ['Emily']
      end

      it "removes blank strings from params before updating Collection metadata" do
        put :update, params: {
          id: collection,
          collection: {
            title: ["My Next Collection "],
            creator: [""]
          }
        }
        expect(assigns[:collection].title).to eq ["My Next Collection "]
        expect(assigns[:collection].creator).to eq []
      end
    end
  end

  describe "#show" do
    context "when signed in" do
      before do
        sign_in user
        [asset1, asset2, asset3].each do |asset|
          asset.member_of_collections = [collection]
          asset.save
        end
      end

      it "returns the collection and its members" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        get :show, params: { id: collection }
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
        expect(assigns[:presenter].title).to match_array collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
      end

      context "and searching" do
        it "returns some works" do
          # "/collections/4m90dv529?utf8=%E2%9C%93&cq=King+Louie&sort="
          get :show, params: { id: collection, cq: "Third" }
          expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
          expect(assigns[:member_docs].map(&:id)).to match_array [asset3].map(&:id)
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
          expect(controller).to receive(:add_breadcrumb).with('My Collections', Hyrax::Engine.routes.url_helpers.dashboard_collections_path(locale: 'en'))
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

  describe "#delete" do
    before { sign_in user }
    context "when it succeeds" do
      it "redirects to My Collections" do
        delete :destroy, params: { id: collection }
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(Hyrax::Engine.routes.url_helpers.dashboard_collections_path(locale: 'en'))
        expect(flash[:notice]).to eq "Collection #{collection.id} was successfully deleted"
      end

      it "returns json" do
        delete :destroy, params: { format: :json, id: collection }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when an error occurs" do
      before do
        allow_any_instance_of(Collection).to receive(:destroy).and_return(nil)
      end
      it "renders the edit view" do
        delete :destroy, params: { id: collection }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
        expect(flash[:notice]).to eq "Collection #{collection.id} could not be deleted"
      end

      it "returns json" do
        delete :destroy, params: { format: :json, id: collection }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "#edit" do
    before { sign_in user }

    it "is successful" do
      get :edit, params: { id: collection }
      expect(response).to be_success
      expect(assigns[:form]).to be_instance_of Hyrax::Forms::CollectionForm
      expect(flash[:notice]).to be_nil
    end

    context "without a referer" do
      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        get :edit, params: { id: collection }
        expect(response).to be_successful
      end
    end

    context "with a referer" do
      before do
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('My Collections', Hyrax::Engine.routes.url_helpers.dashboard_collections_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t("hyrax.collection.browse_view"), collection_path(collection.id, locale: 'en'))
        get :edit, params: { id: collection }
        expect(response).to be_successful
      end
    end
  end
end
