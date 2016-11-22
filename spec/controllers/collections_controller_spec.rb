describe CollectionsController do
  routes { Rails.application.routes }
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
        expect(collection.members).to match_array [asset1, asset2]
      end

      it "adds docs to the collection and adds the collection id to the documents in the collection" do
        post :create, params: {
          batch_document_ids: [asset1.id],
          collection: collection_attrs
        }

        expect(assigns[:collection].members).to eq [asset1]
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
        [asset1, asset2].map(&:save) # bogus_depositor_asset is already saved
        collection.members = [asset1, asset2]
        collection.save!
      end

      it "adds members to the collection" do
        expect do
          put :update, params: { id: collection,
                                 collection: { members: 'add' },
                                 batch_document_ids: [asset3.id]
                               }
        end.to change { collection.reload.members.size }.by(1)
        expect(response).to redirect_to routes.url_helpers.collection_path(collection)
        expect(assigns[:collection].members).to match_array [asset1, asset2, asset3]
      end

      it "removes members from the collection" do
        # TODO: Using size until count is fixed https://github.com/projecthydra-labs/activefedora-aggregation/issues/78
        expect do
          put :update, params: { id: collection,
                                 collection: { members: 'remove' },
                                 batch_document_ids: [asset2]
                               }
        end.to change { collection.reload.members.size }.by(-1)
        expect(assigns[:collection].members).to match_array [asset1]
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
        collection.members = [asset1, asset2, asset3]
        collection.save!
      end

      it 'moves the members' do
        put :update,
            params: {
              id: collection,
              collection: { members: 'move' },
              destination_collection_id: collection2,
              batch_document_ids: [asset2, asset3]
            }
        expect(collection.reload.members).to eq [asset1]
        expect(collection2.reload.members).to match_array [asset2, asset3]
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
        collection.members = [asset1, asset2, asset3]
        collection.save
      end

      it "returns the collection and its members" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :show, params: { id: collection }
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of Sufia::CollectionPresenter
        expect(assigns[:presenter].title).to match_array collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
      end

      context "and searching" do
        it "returns some works" do
          # "/collections/4m90dv529?utf8=%E2%9C%93&cq=King+Louie&sort="
          get :show, params: { id: collection, cq: "Third" }
          expect(assigns[:presenter]).to be_kind_of Sufia::CollectionPresenter
          expect(assigns[:member_docs].map(&:id)).to match_array [asset3].map(&:id)
        end
      end

      context 'when the page parameter is passed' do
        it 'loads the collection (paying no attention to the page param)' do
          get :show, params: { id: collection, page: '2' }
          expect(response).to be_successful
          expect(assigns[:presenter]).to be_kind_of Sufia::CollectionPresenter
          expect(assigns[:presenter].to_s).to eq 'My collection'
        end
      end

      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
          get :show, params: { id: collection }
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
          expect(controller).to receive(:add_breadcrumb).with('My Collections', Sufia::Engine.routes.url_helpers.dashboard_collections_path)
          expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id))
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

  describe "#edit" do
    before { sign_in user }

    it "is successful" do
      get :edit, params: { id: collection }
      expect(response).to be_success
      expect(assigns[:form]).to be_instance_of Sufia::Forms::CollectionForm
      expect(flash[:notice]).to be_nil
    end

    context "without a referer" do
      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :edit, params: { id: collection }
        expect(response).to be_successful
      end
    end

    context "with a referer" do
      before do
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
        expect(controller).to receive(:add_breadcrumb).with('My Collections', Sufia::Engine.routes.url_helpers.dashboard_collections_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t("sufia.collection.browse_view"), collection_path(collection.id))
        get :edit, params: { id: collection }
        expect(response).to be_successful
      end
    end
  end
end
