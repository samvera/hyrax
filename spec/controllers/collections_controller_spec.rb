require 'spec_helper'

describe CollectionsController do
  before(:each) { @routes = Hydra::Collections::Engine.routes }
  before do
    controller.stub(:has_access?).and_return(true)
    User.any_instance.stub(:groups).and_return([])
  end

  let(:user) { FactoryGirl.create(:user) }

  after (:all) do
    Collection.destroy_all
    GenericFile.destroy_all
    User.destroy_all
  end

  describe '#new' do
    before do 
      sign_in user
    end

    it 'should assign @collection' do
      get :new
      assigns(:collection).should be_kind_of(Collection)
    end
  end

  describe '#create' do
    before do 
      sign_in user
    end

    it "should create a Collection" do
      controller.should_receive(:has_access?).and_return(true)
      old_count = Collection.count
      post :create, collection: {title: "My First Collection ", description: "The Description\r\n\r\nand more"}
      Collection.count.should == old_count+1
    end
    it "should create a Collection with files I can access" do
      @asset1 = GenericFile.new(title: "First of the Assets")
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save
      @asset2 = GenericFile.new(title: "Second of the Assets", depositor: user.user_key)
      @asset2.apply_depositor_metadata(user.user_key)
      @asset2.save
      @asset3 = GenericFile.new(title: "Third of the Assets", depositor:'abc')
      @asset3.apply_depositor_metadata('abc')
      @asset3.save
      controller.should_receive(:has_access?).and_return(true)
      old_count = Collection.count
      post :create, collection: {title: "My own Collection ", description: "The Description\r\n\r\nand more"}, batch_document_ids:[@asset1.id, @asset2.id, @asset3.id]
      Collection.count.should == old_count+1
      collection = assigns(:collection)
      collection.members.should include (@asset1)
      collection.members.should include (@asset2)
      collection.members.to_a.should_not include (@asset3) # .to_a to avoid a call to any? which doesn't exist in AF::HABTM
      @asset1.destroy
      @asset2.destroy
      @asset3.destroy
    end

    it "should add docs to collection if batch ids provided and add the collection id to the documents int he colledction" do
      @asset1 = GenericFile.new(title: "First of the Assets")
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save
      post :create, batch_document_ids: [@asset1.id], collection: {title: "My Secong Collection ", description: "The Description\r\n\r\nand more"}
      assigns[:collection].members.should == [@asset1]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset1.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
      asset_results["response"]["numFound"].should == 1
      doc = asset_results["response"]["docs"].first
      doc["id"].should == @asset1.id
      afterupdate = GenericFile.find(@asset1.pid)
      doc[Solrizer.solr_name(:collection)].should == afterupdate.to_solr[Solrizer.solr_name(:collection)]
    end

  end

  describe "#update" do
    before do
      @collection = Collection.new(title: "Collection Title")
      @collection.apply_depositor_metadata(user.user_key)
      @collection.save
      @asset1 = GenericFile.new(title: "First of the Assets")
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save
      @asset2 = GenericFile.new(title: "Second of the Assets", depositor: user.user_key)
      @asset2.apply_depositor_metadata(user.user_key)
      @asset2.save
      @asset3 = GenericFile.new(title: "Third of the Assets", depositor:'abc')
      @asset3.apply_depositor_metadata(user.user_key)
      @asset3.save
      sign_in user
    end
    after do
      @collection.destroy
      @asset1.destroy
      @asset2.destroy
      @asset3.destroy
    end

    it "should set collection on members" do
      put :update, id: @collection.id, collection: {members:"add"}, batch_document_ids:[@asset3.pid,@asset1.pid, @asset2.pid]
      response.should redirect_to Hydra::Collections::Engine.routes.url_helpers.collection_path(@collection.noid)
      assigns[:collection].members.map{|m| m.pid}.sort.should == [@asset2, @asset3, @asset1].map {|m| m.pid}.sort
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.pid}\""],fl:['id',Solrizer.solr_name(:collection)]}
      asset_results["response"]["numFound"].should == 1
      doc = asset_results["response"]["docs"].first
      doc["id"].should == @asset2.id
      afterupdate = GenericFile.find(@asset2.pid)
      doc[Solrizer.solr_name(:collection)].should == afterupdate.to_solr[Solrizer.solr_name(:collection)]
      put :update, id: @collection.id, collection: {members:"remove"}, batch_document_ids:[@asset2]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.pid}\""],fl:['id',Solrizer.solr_name(:collection)]}
      asset_results["response"]["numFound"].should == 1
      doc = asset_results["response"]["docs"].first
      doc["id"].should == @asset2.pid
      afterupdate = GenericFile.find(@asset2.pid)
      doc[Solrizer.solr_name(:collection)].should be_nil
    end
  end

  describe "#show" do
    before do
      @asset1 = GenericFile.new(title: "First of the Assets")
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save!
      @asset2 = GenericFile.new(title: "Second of the Assets", depositor:user.user_key)
      @asset2.apply_depositor_metadata(user.user_key)
      @asset2.save!
      @asset3 = GenericFile.new(title: "Third of the Assets", depositor:user.user_key)
      @asset3.apply_depositor_metadata(user.user_key)
      @asset3.save!
      @asset4 = GenericFile.new(title: "Third of the Assets", depositor:user.user_key)
      @asset4.apply_depositor_metadata(user.user_key)
      @asset4.save!
      @collection = Collection.new
      @collection.title = "My collection"
      @collection.description = "My incredibly detailed description of the collection"
      @collection.apply_depositor_metadata(user.user_key)
      @collection.members = [@asset1,@asset2,@asset3]
      @collection.save!
      controller.stub(:authorize!).and_return(true)
      controller.stub(:apply_gated_search)
    end
    context "when signed in" do
      before do 
        sign_in user
      end

      it "should return the collection and its members" do
        get :show, id: @collection.id
        expect(response).to be_successful
        assigns[:collection].title.should == @collection.title
        ids = assigns[:member_docs].map(&:id)
        expect(ids).to include @asset1.pid, @asset2.pid, @asset3.pid
        expect(ids).to_not include @asset4.pid
      end
    end
    context "not signed in" do
      it "should not show me files in the collection" do
        get :show, id: @collection.id
        assigns[:member_docs].count.should == 0
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
      flash[:notice].should be_nil
    end
  end
end
