require 'spec_helper'

describe CollectionsController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }

  before do
    allow(controller).to receive(:has_access?).and_return(true)

    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
  end

  describe '#index' do
    let!(:collection1) { FactoryGirl.create(:collection, title: ['Beta'], user: user) }
    let!(:collection2) { FactoryGirl.create(:collection, title: ['Alpha'], user: user) }
    let!(:generic_file) { create(:generic_work, user: user) }

    it 'shows a list of collections sorted alphabetically' do
      get :index
      expect(response).to be_successful
      expect(assigns[:document_list].map(&:id)).not_to include generic_file.id
      expect(assigns[:document_list].map(&:id)).to match_array [collection2.id, collection1.id]
    end
  end

  describe '#new' do
    it 'assigns @collection' do
      get :new
      expect(assigns(:collection)).to be_kind_of(Collection)
    end
  end

  describe '#create' do
    it 'creates a Collection' do
      expect do
        post :create, collection: { title: ['My First Collection'],
                                    description: ["The Description\r\n\r\nand more"] }
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].title).to eq ['My First Collection']
      expect(assigns[:collection].description).to eq ["The Description\r\n\r\nand more"]
      expect(assigns[:collection].depositor).to eq(user.user_key)
      expect(response).to redirect_to collection_path(assigns[:collection])
    end

    it 'adds docs to collection if batch ids provided' do
      @asset1 = create(:generic_work, user: user)
      @asset2 = create(:generic_work, user: user)
      post :create, batch_document_ids: [@asset1, @asset2],
                    collection: { title: ['My Secong Collection'],
                                  description: ["The Description\r\n\r\nand more"] }
      expect(assigns[:collection].members).to eq [@asset1, @asset2]
    end

    it 'calls after_create' do
      expect(controller).to receive(:after_create).and_call_original
      post :create, collection: { title: ['My First Collection'],
                                  description: ["The Description\r\n\r\nand more"] }
    end

    it 'adds one doc to collection if batch ids provided and add the collection id to the document in the colledction' do
      @asset1 = create(:generic_work, user: user)
      post :create, batch_document_ids: [@asset1],
                    collection: { title: ['My Second Collection'],
                                  description: ["The Description\r\n\r\nand more"] }
      expect(assigns[:collection].members).to eq [@asset1]
      asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{@asset1.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
      expect(asset_results['response']['numFound']).to eq(1)
      doc = asset_results['response']['docs'].first
      expect(doc['id']).to eq @asset1.id
      afterupdate = GenericWork.find(@asset1.id)
      expect(doc[Solrizer.solr_name(:collection)]).to eq(afterupdate.to_solr[Solrizer.solr_name(:collection)])
    end

    it 'adds docs to collection if batch ids provided and add the collection id to the documents int he colledction' do
      @asset1 = create(:generic_work, user: user)
      @asset2 = create(:generic_work, user: user)
      post :create, batch_document_ids: [@asset1, @asset2],
                    collection: { title: ['My Secong Collection'],
                                  description: ["The Description\r\n\r\nand more"] }
      expect(assigns[:collection].members).to eq [@asset1, @asset2]
      asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{@asset1.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
      expect(asset_results['response']['numFound']).to eq(1)
      doc = asset_results['response']['docs'].first
      expect(doc['id']).to eq(@asset1.id)
      afterupdate = GenericWork.find(@asset1.id)
      expect(doc[Solrizer.solr_name(:collection)]).to eq(afterupdate.to_solr[Solrizer.solr_name(:collection)])
    end
  end

  describe '#update' do
    let(:collection) { FactoryGirl.create(:collection, user: user) }
    before do
      @asset1 = create(:generic_work, user: user)
      @asset2 = create(:generic_work, user: user)
      @asset3 = create(:generic_work, user: user)
    end

    it 'updates collection metadata' do
      put :update, id: collection.id, collection: { title: ['New Title'], description: ['New Description'] }
      expect(response).to redirect_to collection_path(collection)
      expect(assigns[:collection].title).to eq(['New Title'])
      expect(assigns[:collection].description).to eq(['New Description'])
    end

    it 'calls after_update' do
      expect(controller).to receive(:after_update).and_call_original
      put :update, id: collection.id, collection: { title: ['New Title'], description: ['New Description'] }
    end

    context 'when updating fails' do
      before do
        allow_any_instance_of(Collection).to receive(:save).and_return(false)
      end
      it 'renders edit succesfully' do
        put :update, id: collection.id, collection: { title: ['New Title'] }
        expect(response).to render_template 'edit'
      end
    end

    context 'when there are existing members in the collection' do
      it 'supports adding batches of members' do
        collection.members << @asset1
        collection.save!
        put :update, id: collection, collection: { members: 'add' }, batch_document_ids: [@asset2, @asset3]
        expect(response).to redirect_to collection_path(collection)
        expect(assigns[:collection].members).to match_array [@asset2, @asset3, @asset1]
      end

      it 'supports removing batches of members' do
        collection.members = [@asset1, @asset2, @asset3]
        collection.save!
        put :update, id: collection, collection: { members: 'remove' }, batch_document_ids: [@asset1, @asset3]
        expect(response).to redirect_to collection_path(collection)
        expect(assigns[:collection].members).to eq([@asset2])
      end
    end

    it 'supports setting members array' do
      put :update, id: collection, collection: { members: 'add' }, batch_document_ids: [@asset2, @asset3, @asset1]
      expect(response).to redirect_to collection_path(collection)
      expect(assigns[:collection].members).to match_array [@asset2, @asset3, @asset1]
    end

    it 'set/un-sets collection on members' do
      # Add to collection (sets collection on members)
      put :update, id: collection, collection: { members: 'add' }, batch_document_ids: [@asset2, @asset3]
      expect(assigns[:collection].members).to match_array [@asset2, @asset3]

      # Remove from collection (un-sets collection on members)
      put :update, id: collection, collection: { members: 'remove' }, batch_document_ids: [@asset2]
      expect(assigns[:collection].members).not_to include(@asset2)
    end

    context 'when moving members between collections' do
      before do
        collection.members = [@asset1, @asset2, @asset3]
        collection.save!
      end
      let(:collection2) do
        Collection.create(title: ['Some Collection']) do |col|
          col.apply_depositor_metadata(user.user_key)
        end
      end

      it 'moves the members' do
        put :update, id: collection, collection: { members: 'move' },
                     destination_collection_id: collection2, batch_document_ids: [@asset2, @asset3]
        expect(collection.reload.members).to eq [@asset1]
        expect(collection2.reload.members).to match_array [@asset2, @asset3]
      end
    end
  end

  describe '#destroy' do
    describe 'valid collection' do
      let!(:collection) { FactoryGirl.create(:collection, user: user) }
      before do
        expect(controller).to receive(:authorize!).and_return(true)
      end

      it 'deletes the collection' do
        delete :destroy, id: collection
        expect(response).to redirect_to Rails.application.routes.url_helpers.search_catalog_path
        expect(flash[:notice]).to eq('Collection was successfully deleted.')
      end

      it 'calls after_destroy' do
        expect(controller).to receive(:after_destroy).and_call_original
        delete :destroy, id: collection
      end

      it 'updates members' do
        asset1 = create(:generic_work, user: user)
        collection.members << asset1
        collection.save!
        expect(asset1.in_collections).to eq [collection]

        delete :destroy, id: collection
        expect(asset1.in_collections).to eq []
      end
    end

    it 'does not delete an invalid collection' do
      expect { delete :destroy, id: 'zz:-1' }.to raise_error
    end
  end

  describe '#show' do
    context 'when there are no assets in the collection' do
      let(:collection) { FactoryGirl.create(:collection, user: user) }
      it 'shows no assets' do
        get :show, id: collection
        expect(response).to be_successful
        expect(assigns[:presenter].id).to eq collection.id
        expect(assigns[:member_docs]).to be_empty
      end
    end

    context 'with a number of assets' do
      let(:asset1) { create(:generic_work, title: ['First of the Assets'], read_users: [user.user_key]) }
      let(:asset2) { create(:generic_work, title: ['Second of the Assets'], read_users: [user.user_key]) }
      let(:asset3) { create(:generic_work, title: ['Third of the Assets'], read_users: [user.user_key]) }
      let!(:collection) do
        FactoryGirl.create(:collection, members: [asset1, asset2, asset3], user: user)
      end

      it 'queries the collections' do
        get :show, id: collection, cq: 'First'
        expect(assigns[:presenter].id).to eq collection.id
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1.id]
      end

      it 'returns the specified number of rows' do
        get :show, id: collection, rows: '2'
        expect(assigns[:presenter].id).to eq collection.id
        expect(assigns[:member_docs].size).to eq 2
      end

      describe 'additional collections' do
        let(:asset4) { create(:generic_work, user: user, title: [asset1.id.to_s], read_users: [user.user_key]) }
        let!(:collection2) do
          FactoryGirl.create(:collection, members: [asset4], user: user)
        end
        it 'shows only the collections assets' do
          get :show, id: collection
          expect(assigns[:presenter].id).to eq collection.id
          expect(assigns[:member_docs].map(&:id)).to match_array [asset1.id, asset2.id, asset3.id]
        end

        it 'shows only the other collections assets' do
          get :show, id: collection2
          expect(assigns[:presenter].id).to eq collection2.id
          expect(assigns[:member_docs].map(&:id)).to match_array [asset4.id]
        end
      end

      context 'When there are search matches that are not in the collection' do
        let!(:bad_asset1) { create(:generic_work, user: user, title: ["#{asset1.id} #{asset1.title.first}"]) }
        let!(:bad_asset2) { create(:generic_work, user: user, title: ["#{asset1.id} #{asset1.title.first}"]) }

        # NOTE: This test depends on title_tesim being in the qf in solrconfig.xml
        it 'only shows the collection assets' do
          get :show, id: collection, cq: "\"#{asset1.title.first}\""
          expect(assigns[:presenter].id).to eq collection.id
          expect(assigns[:member_docs].map(&:id)).not_to include bad_asset1.id, bad_asset2.id
          expect(assigns[:member_docs].map(&:id)).to match_array [asset1.id]
        end
      end
    end
  end
end
