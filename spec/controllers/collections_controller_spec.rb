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

    it "should add docs to collection if batch ids provided and add the collection id to the documents int he colledction" do
      @asset1 = GenericFile.new(title: ["First of the Assets"])
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save
      post :create, batch_document_ids: [@asset1.id],
        collection: { title: "My Secong Collection ", description: "The Description\r\n\r\nand more" }
      expect(assigns[:collection].members).to eq [@asset1]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset1.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
      expect(asset_results["response"]["numFound"]).to eq 1
      doc = asset_results["response"]["docs"].first
      expect(doc["id"]).to eq @asset1.id
      afterupdate = GenericFile.find(@asset1.pid)
      expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]
    end

  end

  describe "#update" do
    before do
      @collection = Collection.new(title: "Collection Title")
      @collection.apply_depositor_metadata(user.user_key)
      @collection.save
      @asset1 = GenericFile.new(title: ["First of the Assets"])
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save
      @asset2 = GenericFile.new(title: ["Second of the Assets"], depositor: user.user_key)
      @asset2.apply_depositor_metadata(user.user_key)
      @asset2.save
      @asset3 = GenericFile.new(title: ["Third of the Assets"], depositor:'abc')
      @asset3.apply_depositor_metadata(user.user_key)
      @asset3.save
      sign_in user
    end

    it "should set collection on members" do
      put :update, id: @collection.id, collection: {members:"add"}, batch_document_ids: [@asset3.pid, @asset1.pid, @asset2.pid]
      expect(response).to redirect_to routes.url_helpers.collection_path(@collection.noid)
      expect(assigns[:collection].members).to match_array [@asset2, @asset3, @asset1]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.pid}\""],fl:['id',Solrizer.solr_name(:collection)]}
      expect(asset_results["response"]["numFound"]).to eq 1
      doc = asset_results["response"]["docs"].first
      expect(doc["id"]).to eq @asset2.id
      afterupdate = GenericFile.find(@asset2.pid)
      expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]
      put :update, id: @collection.id, collection: {members:"remove"}, batch_document_ids: [@asset2]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.pid}\""],fl:['id',Solrizer.solr_name(:collection)]}
      expect(asset_results["response"]["numFound"]).to eq 1
      doc = asset_results["response"]["docs"].first
      expect(doc["id"]).to eq @asset2.id
      afterupdate = GenericFile.find(@asset2.pid)
      expect(doc[Solrizer.solr_name(:collection)]).to be_nil
    end
  end

  describe "#show" do
    before do
      @asset1 = GenericFile.new(title: ["First of the Assets"])
      @asset1.apply_depositor_metadata(user.user_key)
      @asset2 = GenericFile.new(title: ["Second of the Assets"], depositor:user.user_key)
      @asset2.apply_depositor_metadata(user.user_key)
      @asset3 = GenericFile.new(title: ["Third of the Assets"], depositor:user.user_key)
      @asset3.apply_depositor_metadata(user.user_key)
      @asset4 = GenericFile.new(title: ["Third of the Assets"], depositor:user.user_key)
      @asset4.apply_depositor_metadata(user.user_key)
      @collection = Collection.new
      @collection.title = "My collection"
      @collection.description = "My incredibly detailed description of the collection"
      @collection.apply_depositor_metadata(user.user_key)
      @collection.members = [@asset1,@asset2,@asset3]
      @collection.save!
      allow(controller).to receive(:authorize!).and_return(true)
    end
    context "when signed in" do
      before do 
        sign_in user
      end

      it "should return the collection and its members" do
        get :show, id: @collection.id
        expect(response).to be_successful
        expect(assigns[:collection].title).to eq @collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [@asset1, @asset2, @asset3].map(&:id)
      end
      it "should set the breadcrumb trail" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :show, id: @collection.id
      end
    end
    context "not signed in" do
      it "should not show me files in the collection" do
        get :show, id: @collection.id
        expect(assigns[:member_docs].count).to eq 0
      end
    end
  end

  describe "#edit" do
    before do
      @collection = Collection.new(title: "My collection", description: "My incredibly detailed description of the collection")
      @collection.apply_depositor_metadata(user.user_key)
      @collection.save
      sign_in user
    end
    it "should not show flash" do
      get :edit, id: @collection.id
      expect(flash[:notice]).to be_nil
    end
  end
end
