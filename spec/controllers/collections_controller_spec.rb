require 'spec_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  before do
    allow(controller).to receive(:has_access?).and_return(true)
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end

  let(:user) { FactoryGirl.create(:admin) }
  let(:otheruser) { FactoryGirl.create(:user) }
  let(:work1) { FactoryGirl.create(:generic_work, user:user) }
  let(:work2) { FactoryGirl.create(:generic_work, user: user) }
  let(:my_public_generic_work) { FactoryGirl.create(:public_generic_work, user:user) }
  let(:my_other_public_generic_work) { FactoryGirl.create(:public_generic_work, user:user) }
  let(:private_asset_not_mine) { FactoryGirl.create(:private_generic_work, user:otheruser) }
  let(:public_asset_not_mine) { FactoryGirl.create(:public_generic_work, user:otheruser) }
  let(:collection) { FactoryGirl.create(:collection, user:user) }

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
      }.to change {Collection.count}.by 1
    end
    it "should create a Collection with files I can access" do
      expect {
        post :create, collection: {title: "My own Collection ", description: "The Description\r\n\r\nand more"}, batch_document_ids:[work1.id, work2.id, private_asset_not_mine.id]
      }.to change {Collection.count}.by 1
      collection = assigns(:collection)
      expect(collection.members).to include work1
      expect(collection.members).to include work2
      expect(collection.members).to_not include private_asset_not_mine
      work1.destroy
      work2.destroy
      my_public_generic_work.destroy
    end

    it "should add docs to collection if batch ids provided and add the collection id to the documents int he colledction" do
      post :create, batch_document_ids: [work1.id], collection: {title: "My Secong Collection ", description: "The Description\r\n\r\nand more"}
      expect(assigns[:collection].members).to eq [work1]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{work1.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
      expect(asset_results["response"]["numFound"]).to eq 1
      doc = asset_results["response"]["docs"].first
      expect(doc["id"]).to eq work1.id
      afterupdate = GenericFile.find(work1.pid)
      expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]
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
      expect(assigns[:collection].members.map(&:pid)).to match_array([work2, my_public_generic_work, work1].map(&:pid))
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{work2.pid}\""],fl:['id',Solrizer.solr_name(:collection)]}
      expect(asset_results["response"]["numFound"]).to eq 1
      doc = asset_results["response"]["docs"].first
      expect(doc["id"]).to eq work2.id
      afterupdate = GenericFile.find(work2.pid)
      expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]
      put :update, id: collection.id, collection: {members: "remove"}, batch_document_ids: [work2]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{work2.pid}\""],fl:['id',Solrizer.solr_name(:collection)]}
      expect(asset_results["response"]["numFound"]).to eq 1
      doc = asset_results["response"]["docs"].first
      expect(doc["id"]).to eq work2.id
      afterupdate = GenericFile.find(work2.pid)
      expect(doc[Solrizer.solr_name(:collection)]).to be_nil
    end

    describe "adding members" do
      it "should add members and update all of the relevant solr documents" do
        expect(collection.members).to_not include my_other_public_generic_work
        solr_doc_before_remove = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, my_other_public_generic_work.pid).send(:solr_doc)
        expect(solr_doc_before_remove[Solrizer.solr_name(:collection)]).to be_nil
        put :update, id: collection.id, collection: {members:"add"}, batch_document_ids:[my_other_public_generic_work.pid]
        expect(collection.reload.members).to include my_other_public_generic_work
        solr_doc_after_add = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, my_other_public_generic_work.pid).send(:solr_doc)
        expect(solr_doc_after_add[Solrizer.solr_name(:collection)]).to eq [collection.pid]
      end
    end

    describe "removing members" do
      before do
        collection.members << public_asset_not_mine
        collection.save
      end
      it "should remove members and update all of the relevant solr documents" do
        # BUG: This is returning inaccurate information
        #     expect(collection.reload.members).to include public_asset_not_mine
        solr_doc_before_remove = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, public_asset_not_mine.pid).send(:solr_doc)
        expect(solr_doc_before_remove[Solrizer.solr_name(:collection)]).to eq [collection.pid]
        put :update, id: collection.id, collection: {members:"remove"}, batch_document_ids:[public_asset_not_mine.pid]
        expect(collection.reload.members.count).to eq 0
        solr_doc_after_remove = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, public_asset_not_mine.pid).send(:solr_doc)
        expect(solr_doc_after_remove[Solrizer.solr_name(:collection)]).to be_nil
      end
    end
  end

  describe "#show" do
    before do
      collection.members = [work1,work2,my_public_generic_work,private_asset_not_mine,public_asset_not_mine]
      collection.save
      allow(controller).to receive(:authorize!).and_return(true)
      allow(controller).to receive(:apply_gated_search)
    end

    context "when signed in" do
      before do
        sign_in user
      end

      it "should return the collection and its members I have access to" do
        get :show, id: collection.id
        expect(response).to be_successful
        expect(assigns[:collection].title).to eq collection.title
        ids = assigns[:member_docs].map(&:id)
        expect(ids).to include work1.pid, work2.pid, my_public_generic_work.pid, public_asset_not_mine.pid
        expect(ids).to_not include my_other_public_generic_work.pid, private_asset_not_mine.pid
      end

      context "as an admin" do
        before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
        it "shows all the collection members" do
          get :show, id: collection.id
          expect(response).to be_successful
          expect(assigns[:collection].title).to eq collection.title
          ids = assigns[:member_docs].map(&:id)
          expect(ids).to include work1.pid, work2.pid, my_public_generic_work.pid, public_asset_not_mine.pid, private_asset_not_mine.pid
          expect(ids).to_not include my_other_public_generic_work.pid
        end
      end

      context "when query limited to 'mine'" do
        it "should return only the collection members that I own" do
          get :show, id: collection.id, owner:'mine'
          expect(response).to be_successful
          expect(assigns[:collection].title).to eq collection.title
          ids = assigns[:member_docs].map(&:id)
          expect(ids).to include work1.pid, work2.pid, my_public_generic_work.pid
          expect(ids).to_not include my_other_public_generic_work.pid, private_asset_not_mine.pid, public_asset_not_mine.pid
        end
      end

      context "when items have been added and removed" do
        it "should return the items that are in the collection and not return items that have been removed" do
          put :update, id: collection.id, collection: {members:"remove"}, batch_document_ids:[public_asset_not_mine.pid]
          panm_solr_doc = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, public_asset_not_mine.pid).send(:solr_doc)
          expect(panm_solr_doc[Solrizer.solr_name(:collection)]).to be_nil
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
        expect(assigns[:member_docs].count).to eq 2
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
      expect(flash[:notice]).to be_nil
    end
  end
end
