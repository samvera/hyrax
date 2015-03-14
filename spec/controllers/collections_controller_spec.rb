require 'spec_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end

  let(:user) { FactoryGirl.create(:user) }

  describe '#new' do
    before do
      sign_in user
    end

    it 'should assign @collection' do
      get :new
      expect(assigns(:collection)).to be_kind_of(Collection)
    end
  end

  describe '#create' do
    before do
      sign_in user
    end

    it "should create a Collection" do
      expect {
        post :create, collection: {title: "My First Collection ", description: "The Description\r\n\r\nand more"}
      }.to change{ Collection.count }.by(1)
    end

    it "should remove blank strings from params before creating Collection" do
      expect {
        post :create, collection: {
          title: "My First Collection ", creator: [""] }
      }.to change{ Collection.count }.by(1)
      expect(assigns[:collection].title).to eq("My First Collection ")
      expect(assigns[:collection].creator).to eq([])
    end

    it "should create a Collection with files I can access" do
      @asset1 = GenericFile.new(title: ["First of the Assets"])
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save
      @asset2 = GenericFile.new(title: ["Second of the Assets"], depositor: user.user_key)
      @asset2.apply_depositor_metadata(user.user_key)
      @asset2.save
      @asset3 = GenericFile.new(title: ["Third of the Assets"], depositor:'abc')
      @asset3.apply_depositor_metadata('abc')
      @asset3.save
      expect {
        post :create, collection: { title: "My own Collection", description: "The Description\r\n\r\nand more" },
          batch_document_ids: [@asset1.id, @asset2.id, @asset3.id]
      }.to change{ Collection.count }.by(1)
      collection = assigns(:collection)
      expect(collection.members).to match_array [@asset1, @asset2]
    end

    it "should add docs to the collection if a batch id is provided and add the collection id to the documents in the collection" do
      @asset1 = GenericFile.new(title: ["First of the Assets"])
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save
      post :create, batch_document_ids: [@asset1.id],
        collection: { title: "My Second Collection ", description: "The Description\r\n\r\nand more" }
      expect(assigns[:collection].members).to eq [@asset1]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset1.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
      expect(asset_results["response"]["numFound"]).to eq 1
      doc = asset_results["response"]["docs"].first
      expect(doc["id"]).to eq @asset1.id
      afterupdate = GenericFile.find(@asset1.id)
      expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]
    end

  end

  describe "#update" do
    before { sign_in user }

    let(:collection) do
      Collection.create(title: "Collection Title") do |collection|
        collection.apply_depositor_metadata(user.user_key)
      end
    end

    context "a collections members" do
      before do
        @asset1 = GenericFile.new(title: ["First of the Assets"])
        @asset1.apply_depositor_metadata(user.user_key)
        @asset1.save
        @asset2 = GenericFile.new(title: ["Second of the Assets"], depositor: user.user_key)
        @asset2.apply_depositor_metadata(user.user_key)
        @asset2.save
        @asset3 = GenericFile.new(title: ["Third of the Assets"], depositor:'abc')
        @asset3.apply_depositor_metadata(user.user_key)
        @asset3.save
      end

      it "should set collection on members" do
        put :update, id: collection, collection: {members:"add"}, batch_document_ids: [@asset3.id, @asset1.id, @asset2.id]
        expect(response).to redirect_to routes.url_helpers.collection_path(collection)
        expect(assigns[:collection].members).to match_array [@asset2, @asset3, @asset1]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq @asset2.id
        afterupdate = GenericFile.find(@asset2.id)
        expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]
        put :update, id: collection, collection: {members:"remove"}, batch_document_ids: [@asset2]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq @asset2.id
        afterupdate = GenericFile.find(@asset2.id)
        expect(doc[Solrizer.solr_name(:collection)]).to be_nil
      end
    end

    context "updating a collections metadata" do
      it "should save the metadata" do
        put :update, id: collection, collection: { creator: ['Emily'] }
        collection.reload
        expect(collection.creator).to eq ['Emily']
      end

      it "should remove blank strings from params before updating Collection metadata" do
        put :update, id: collection, collection: {
          title: "My Next Collection ", creator: [""] }
        expect(assigns[:collection].title).to eq("My Next Collection ")
        expect(assigns[:collection].creator).to eq([])
      end

    end
  end

  describe "#show" do
    let(:asset1) do
      GenericFile.new(title: ["First of the Assets"]) { |a| a.apply_depositor_metadata(user) }
    end

    let(:asset2) do
      GenericFile.new(title: ["Second of the Assets"]) { |a| a.apply_depositor_metadata(user) }
    end

    let(:asset3) do
      GenericFile.new(title: ["Third of the Assets"]) { |a| a.apply_depositor_metadata(user) }
    end

    let!(:asset4) do
      GenericFile.create(title: ["Fourth of the Assets"]) { |a| a.apply_depositor_metadata(user) }
    end

    let(:collection) do
      Collection.create(title: "My collection",
        description: "My incredibly detailed description of the collection",
        members: [asset1, asset2, asset3]) { |c| c.apply_depositor_metadata(user) }
    end

    context "when signed in" do
      before { sign_in user }

      it "should return the collection and its members" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :show, id: collection
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of Sufia::CollectionPresenter
        expect(assigns[:collection].title).to eq collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
      end
    end

    context "not signed in" do
      it "should not show me files in the collection" do
        get :show, id: collection
        expect(assigns[:member_docs].count).to eq 0
      end
    end
  end

  describe "#edit" do
    let(:collection) do
      Collection.create(title: "My collection",
        description: "My incredibly detailed description of the collection") do |c|
        c.apply_depositor_metadata(user)
      end
    end

    before { sign_in user }

    it "should not show flash" do
      get :edit, id: collection
      expect(flash[:notice]).to be_nil
    end
  end
end
