require 'spec_helper'

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
      expect {
        post :create, collection: { title: ["My First Collection "],
                                    description: "The Description\r\n\r\nand more" }
      }.to change { Collection.count }.by(1)
    end

    it "removes blank strings from params before creating Collection" do
      expect {
        post :create, collection: {
          title: ["My First Collection "], creator: [""]
        }
      }.to change { Collection.count }.by(1)
      expect(assigns[:collection].title).to eq ["My First Collection "]
      expect(assigns[:collection].creator).to eq []
    end

    context "with files I can access" do
      it "creates a collection using only the accessible files" do
        expect {
          post :create, collection: { title: ["My own Collection"],
                                      description: "The Description\r\n\r\nand more" },
                        batch_document_ids: [asset1.id, asset2.id, unowned_asset.id]
        }.to change { Collection.count }.by(1)
        collection = assigns(:collection)
        expect(collection.members).to match_array [asset1, asset2]
      end

      it "adds docs to the collection and adds the collection id to the documents in the collection" do
        post :create, batch_document_ids: [asset1.id],
                      collection: { title: "My Second Collection ",
                                    description: "The Description\r\n\r\nand more" }
        expect(assigns[:collection].members).to eq [asset1]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params: { fq: ["id:\"#{asset1.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq asset1.id
        afterupdate = GenericWork.find(asset1.id)
        expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]
      end
    end

    context "when setting visibility" do
      it 'creates a public Collection' do
        col1 = create(:public_collection, title: ["Public collection"])
        expect(col1.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end

      it 'creates an institutional Collection' do
        col1 = create(:institution_collection, title: ["Institution collection"])
        expect(col1.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end

      it 'creates a private Collection' do
        col1 = create(:private_collection, title: ["Private collection"])
        expect(col1.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end

  describe "#update" do
    before { sign_in user }

    context "a collections members" do
      it "sets collection on members" do
        put :update, id: collection,
                     collection: { members: "add" },
                     batch_document_ids: [asset3.id, asset1.id, asset2.id]
        expect(response).to redirect_to routes.url_helpers.collection_path(collection)
        expect(assigns[:collection].members).to match_array [asset2, asset3, asset1]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params: { fq: ["id:\"#{asset2.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq asset2.id
        afterupdate = GenericWork.find(asset2.id)
        expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]

        put :update, id: collection,
                     collection: { members: "remove" },
                     batch_document_ids: [asset2]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params: { fq: ["id:\"#{asset2.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq asset2.id
        expect(doc[Solrizer.solr_name(:collection)]).to be_nil
      end
    end

    context "updating a collections metadata" do
      it "saves the metadata" do
        put :update, id: collection, collection: { creator: ['Emily'] }
        collection.reload
        expect(collection.creator).to eq ['Emily']
      end

      it "removes blank strings from params before updating Collection metadata" do
        put :update, id: collection, collection: {
          title: ["My Next Collection "], creator: [""]
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
        get :show, id: collection
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of Sufia::CollectionPresenter
        expect(assigns[:presenter].title).to eq collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
      end

      context "and searching" do
        it "returns some works" do
          # "/collections/4m90dv529?utf8=%E2%9C%93&cq=King+Louie&sort="
          get :show, id: collection, cq: "Third"

          expect(assigns[:member_docs].map(&:id)).to match_array [asset3].map(&:id)
        end
      end

      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
          get :show, id: collection
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          allow(controller.request).to receive(:referer).and_return('foo')
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
          expect(controller).to receive(:add_breadcrumb).with('My Collections', Sufia::Engine.routes.url_helpers.dashboard_collections_path)
          expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id))
          get :show, id: collection
          expect(response).to be_successful
        end
      end
    end

    context "not signed in" do
      it "does not show me files in the collection" do
        get :show, id: collection
        expect(assigns[:member_docs].count).to eq 0
      end
    end
  end

  describe "#edit" do
    before { sign_in user }

    it "is successful" do
      get :edit, id: collection
      expect(response).to be_success
      expect(assigns[:form]).to be_instance_of Sufia::Forms::CollectionForm
      expect(flash[:notice]).to be_nil
    end

    context "without a referer" do
      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :edit, id: collection
        expect(response).to be_successful
      end
    end

    context "with a referer" do
      before do
        allow(controller.request).to receive(:referer).and_return('foo')
      end

      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
        expect(controller).to receive(:add_breadcrumb).with('My Collections', Sufia::Engine.routes.url_helpers.dashboard_collections_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t("sufia.collection.browse_view"), collection_path(collection.id))
        get :edit, id: collection
        expect(response).to be_successful
      end
    end
  end
end
