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
      @my_public_asset_in_collection = GenericFile.new(title: "Third of the Assets", depositor:'abc')
      @my_public_asset_in_collection.apply_depositor_metadata('abc')
      @my_public_asset_in_collection.save
      old_count = Collection.count
      post :create, collection: {title: "My own Collection ", description: "The Description\r\n\r\nand more"}, batch_document_ids:[@asset1.id, @asset2.id, @my_public_asset_in_collection.id]
      Collection.count.should == old_count+1
      collection = assigns(:collection)
      collection.members.should include (@asset1)
      collection.members.should include (@asset2)
      collection.members.should_not include (@my_public_asset_in_collection)
      @asset1.destroy
      @asset2.destroy
      @my_public_asset_in_collection.destroy
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
      @my_public_asset_in_collection = GenericFile.new(title: "Third of the Assets", depositor:'abc')
      @my_public_asset_in_collection.apply_depositor_metadata(user.user_key)
      @my_public_asset_in_collection.save
      sign_in user
    end
    after do
      @collection.destroy
      @asset1.destroy
      @asset2.destroy
      @my_public_asset_in_collection.destroy
    end

    it "should set collection on members" do
      put :update, id: @collection.id, collection: {members:"add"}, batch_document_ids:[@my_public_asset_in_collection.pid,@asset1.pid, @asset2.pid]
      response.should redirect_to Hydra::Collections::Engine.routes.url_helpers.collection_path(@collection.pid)
      assigns[:collection].members.map{|m| m.pid}.sort.should == [@asset2, @my_public_asset_in_collection, @asset1].map {|m| m.pid}.sort
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
    let(:other_user) { FactoryGirl.create(:user) }
    before do
      @asset1 = GenericFile.new(title: "First of the Assets")
      @asset1.apply_depositor_metadata(user.user_key)
      @asset1.save!
      @asset2 = GenericFile.new(title: "Second of the Assets", depositor:user.user_key)
      @asset2.apply_depositor_metadata(user.user_key)
      @asset2.save!
      @my_public_asset_in_collection = GenericFile.new(title: "Third of the Assets", depositor:user.user_key)
      @my_public_asset_in_collection.apply_depositor_metadata(user.user_key)
      @my_public_asset_in_collection.visibility = "open"
      @my_public_asset_in_collection.save!
      @my_public_asset_outside_collection = GenericFile.new(title: "Fourth of the Assets", depositor:user.user_key)
      @my_public_asset_outside_collection.apply_depositor_metadata(user.user_key)
      @my_public_asset_outside_collection.visibility = "open"
      @my_public_asset_outside_collection.save
      @private_asset_not_mine = GenericFile.new(title: "Fifth of the Assets", depositor:other_user.user_key)
      @private_asset_not_mine.apply_depositor_metadata(other_user.user_key)
      @private_asset_not_mine.visibility = "restricted"
      @private_asset_not_mine.save!
      @public_asset_not_mine = GenericFile.new(title: "Sixth of the Assets", depositor:other_user.user_key)
      @public_asset_not_mine.apply_depositor_metadata(other_user.user_key)
      @public_asset_not_mine.visibility = "open"
      @public_asset_not_mine.save!
      @collection = Collection.new
      @collection.title = "My collection"
      @collection.description = "My incredibly detailed description of the collection"
      @collection.apply_depositor_metadata(user.user_key)
      @collection.members = [@asset1,@asset2,@my_public_asset_in_collection,@private_asset_not_mine,@public_asset_not_mine]
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
        expect(ids).to include @asset1.pid, @asset2.pid, @my_public_asset_in_collection.pid, @public_asset_not_mine.pid
        expect(ids).to_not include @my_public_asset_outside_collection.pid, @private_asset_not_mine.pid
      end

      context "when query limited to 'mine'" do
        it "should return only the collection members that I own" do
          get :show, id: @collection.id, owner:'mine'
          expect(response).to be_successful
          assigns[:collection].title.should == @collection.title
          ids = assigns[:member_docs].map(&:id)
          expect(ids).to include @asset1.pid, @asset2.pid, @my_public_asset_in_collection.pid
          expect(ids).to_not include @my_public_asset_outside_collection.pid, @private_asset_not_mine.pid, @public_asset_not_mine.pid
        end
      end
    end
    context "not signed in" do
      it "should only show me public access files in the collection" do
        get :show, id: @collection.id
        assigns[:member_docs].count.should == 2
        ids = assigns[:member_docs].map(&:id)
        expect(ids).to include @my_public_asset_in_collection.pid, @public_asset_not_mine.pid
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
