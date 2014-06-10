require 'spec_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  before do
    controller.stub(:has_access?).and_return(true)
    User.any_instance.stub(:groups).and_return([])
  end

  let(:user) { FactoryGirl.create(:admin) }
  let(:otheruser) { FactoryGirl.create(:user) }
  let(:work1) { FactoryGirl.create(:generic_work, title: "First of the Assets", user:user) }
  let(:work2) { FactoryGirl.create(:generic_work, title: "Second of the Assets", user: user) }
  let(:my_public_generic_work) { FactoryGirl.create(:public_generic_work, title: "Third of the Assets (public)", user:user) }
  let(:my_other_public_generic_work) { FactoryGirl.create(:public_generic_work, title: "Fourth of the Assets", user:user) }
  let(:private_asset_not_mine) { FactoryGirl.create(:private_generic_work, title: "Fifth of the Assets", user:otheruser) }
  let(:public_asset_not_mine) { FactoryGirl.create(:public_generic_work, title: "Sixth of the Assets", user:otheruser) }
  let(:collection) { FactoryGirl.create(:collection, title:"My collection", description:"My incredibly detailed description of the collection", user:user) }

  after (:all) do
    Collection.destroy_all
    GenericWork.destroy_all
    User.destroy_all
  end

  describe '#new' do
    before do
      sign_in user
    end

    it 'should assign collection' do
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
      old_count = Collection.count
      post :create, collection: {title: "My own Collection ", description: "The Description\r\n\r\nand more"}, batch_document_ids:[work1.id, work2.id, private_asset_not_mine.id]
      Collection.count.should == old_count+1
      collection = assigns(:collection)
      collection.members.should include (work1)
      collection.members.should include (work2)
      collection.members.should_not include (private_asset_not_mine)
      work1.destroy
      work2.destroy
      my_public_generic_work.destroy
    end

    it "should add docs to collection if batch ids provided and add the collection id to the documents int he colledction" do
      post :create, batch_document_ids: [work1.id], collection: {title: "My Secong Collection ", description: "The Description\r\n\r\nand more"}
      assigns[:collection].members.should == [work1]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{work1.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
      asset_results["response"]["numFound"].should == 1
      doc = asset_results["response"]["docs"].first
      doc["id"].should == work1.id
      afterupdate = GenericFile.find(work1.pid)
      doc[Solrizer.solr_name(:collection)].should == afterupdate.to_solr[Solrizer.solr_name(:collection)]
    end

  end

  describe "#update" do
    before do
      sign_in user
    end
    after do
      collection.destroy
      work1.destroy
      work2.destroy
      my_public_generic_work.destroy
    end

    it "should set collection on members" do
      put :update, id: collection.id, collection: {members:"add"}, batch_document_ids:[my_public_generic_work.pid,work1.pid, work2.pid]
      expect(response).to redirect_to collection_path(collection)
      assigns[:collection].members.map{|m| m.pid}.sort.should == [work2, my_public_generic_work, work1].map {|m| m.pid}.sort
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{work2.pid}\""],fl:['id',Solrizer.solr_name(:collection)]}
      asset_results["response"]["numFound"].should == 1
      doc = asset_results["response"]["docs"].first
      doc["id"].should == work2.id
      afterupdate = GenericFile.find(work2.pid)
      doc[Solrizer.solr_name(:collection)].should == afterupdate.to_solr[Solrizer.solr_name(:collection)]
      put :update, id: collection.id, collection: {members:"remove"}, batch_document_ids:[work2]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{work2.pid}\""],fl:['id',Solrizer.solr_name(:collection)]}
      asset_results["response"]["numFound"].should == 1
      doc = asset_results["response"]["docs"].first
      doc["id"].should == work2.pid
      afterupdate = GenericFile.find(work2.pid)
      doc[Solrizer.solr_name(:collection)].should be_nil
    end
    describe "adding members" do
      it "should add members and update all of the relevant solr documents" do
        collection.members.should_not include my_other_public_generic_work
        solr_doc_before_remove = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, my_other_public_generic_work.pid).send(:solr_doc)
        solr_doc_before_remove[Solrizer.solr_name(:collection)].should be_nil
        put :update, id: collection.id, collection: {members:"add"}, batch_document_ids:[my_other_public_generic_work.pid]
        collection.reload.members.should include my_other_public_generic_work
        solr_doc_after_add = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, my_other_public_generic_work.pid).send(:solr_doc)
        solr_doc_after_add[Solrizer.solr_name(:collection)].should == [collection.pid]
      end
    end
    describe "removing members" do
      before do
        collection.members << public_asset_not_mine
        collection.save
      end
      it "should remove members and update all of the relevant solr documents" do
        # BUG: This is returning inaccurate information
        #     collection.reload.members.should include public_asset_not_mine
        solr_doc_before_remove = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, public_asset_not_mine.pid).send(:solr_doc)
        solr_doc_before_remove[Solrizer.solr_name(:collection)].should == [collection.pid]
        put :update, id: collection.id, collection: {members:"remove"}, batch_document_ids:[public_asset_not_mine.pid]
        expect(collection.reload.members.count).to eq 0
        solr_doc_after_remove = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, public_asset_not_mine.pid).send(:solr_doc)
        solr_doc_after_remove[Solrizer.solr_name(:collection)].should be_nil
      end
    end
  end

  describe "#show" do
    before do
      collection.members = [work1,work2,my_public_generic_work,private_asset_not_mine,public_asset_not_mine]
      collection.save
      controller.stub(:authorize!).and_return(true)
      controller.stub(:apply_gated_search)
    end
    context "when signed in" do
      before do
        sign_in user
      end

      it "should return the collection and its members I have access to" do
        get :show, id: collection.id
        expect(response).to be_successful
        assigns[:collection].title.should == collection.title
        ids = assigns[:member_docs].map(&:id)
        expect(ids).to include work1.pid, work2.pid, my_public_generic_work.pid, public_asset_not_mine.pid
        expect(ids).to_not include my_other_public_generic_work.pid, private_asset_not_mine.pid
      end

      context "as an admin" do
        before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
        it "shows all the collection members" do
          get :show, id: collection.id
          expect(response).to be_successful
          assigns[:collection].title.should == collection.title
          ids = assigns[:member_docs].map(&:id)
          expect(ids).to include work1.pid, work2.pid, my_public_generic_work.pid, public_asset_not_mine.pid, private_asset_not_mine.pid
          expect(ids).to_not include my_other_public_generic_work.pid
        end
      end

      context "when query limited to 'mine'" do
        it "should return only the collection members that I own" do
          get :show, id: collection.id, owner:'mine'
          expect(response).to be_successful
          assigns[:collection].title.should == collection.title
          ids = assigns[:member_docs].map(&:id)
          expect(ids).to include work1.pid, work2.pid, my_public_generic_work.pid
          expect(ids).to_not include my_other_public_generic_work.pid, private_asset_not_mine.pid, public_asset_not_mine.pid
        end
      end

      context "when items have been added and removed" do
        it "should return the items that are in the collection and not return items that have been removed" do
          put :update, id: collection.id, collection: {members:"remove"}, batch_document_ids:[public_asset_not_mine.pid]
          panm_solr_doc = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, public_asset_not_mine.pid).send(:solr_doc)
          panm_solr_doc[Solrizer.solr_name(:collection)].should be_nil
          controller.batch = nil
          put :update, id: collection.id, collection: {members:"add"}, batch_document_ids:[my_other_public_generic_work.pid]
          get :show, id: collection.id
          ids = assigns[:member_docs].map(&:id)
          expect(ids).to include work1.pid, work2.pid, my_public_generic_work.pid, my_other_public_generic_work.pid
          expect(ids).to_not include public_asset_not_mine.pid
        end
      end
    end
    context "not signed in" do
      it "should only show me public access files in the collection" do
        get :show, id: collection.id
        assigns[:member_docs].count.should == 2
        ids = assigns[:member_docs].map(&:id)
        expect(ids).to include my_public_generic_work.pid, public_asset_not_mine.pid
      end
    end
  end

  describe "#edit" do
    before do
      collection = Collection.new(title: "My collection", description: "My incredibly detailed description of the collection")
      collection.apply_depositor_metadata(user.user_key)
      collection.save
      sign_in user
    end
    it "should not show flash" do
      get :edit, id: collection.id
      flash[:notice].should be_nil
    end
  end
end
