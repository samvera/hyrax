require 'spec_helper'

describe CollectionsController do
  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end

  let(:user) { create(:user) }
  let(:asset1) { build(:generic_work, title: ['First of the Assets'], user: user) }
  let(:asset2) { build(:generic_work,
                       title: ['Second of the Assets'],
                       user: user,
                       depositor: user.user_key) }
  let(:asset3) { build(:generic_work, title: ['Third of the Assets']) }
  let(:asset4) { create(:generic_work,
                        title: ['Fourth of the Assets'],
                        user: user) }
  let(:bogus_depositor_asset) { create(:generic_work,
                                       title: ['Bogus Asset'],
                                       depositor: 'abc') }
  let(:collection_attrs) do
    { title: ['My First Collection'], description: ["The Description\r\n\r\nand more"] }
  end

  let(:collection) { create(:collection, title: ['Collection Title'], user: user) }

  describe '#new' do
    before { sign_in user }

    it 'assigns @collection' do
      get :new
      expect(assigns(:collection)).to be_kind_of(Collection)
    end
  end

  describe '#create' do
    before { sign_in user }

    it 'creates a Collection' do
      expect do
        post :create, params: { collection: collection_attrs.merge(visibility: 'open') }
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].visibility).to eq 'open'
    end

    it 'removes blank strings from params before creating Collection' do
      expect do
        post :create, params: { collection: collection_attrs.merge(creator: ['']) }
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].title).to eq ['My First Collection']
      expect(assigns[:collection].creator).to eq([])
    end

    it 'creates a Collection with files I can access' do
      [asset1, asset2].map(&:save) # bogus_depositor_asset is already saved
      expect do
        post :create, params: { collection: collection_attrs,
                                batch_document_ids: [asset1.id, asset2.id, bogus_depositor_asset.id]
                              }
      end.to change { Collection.count }.by(1)
      collection = assigns(:collection)
      expect(collection.member_objects).to match_array [asset1, asset2]
    end

    it 'adds docs to the collection if a batch id is provided and add the collection id to the documents in the collection' do
      asset1.save
      post :create, params: { batch_document_ids: [asset1.id], collection: collection_attrs }
      expect(assigns[:collection].member_objects).to eq [asset1]

      asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{asset1.id}\""], fl: ['id'] }
      expect(asset_results['response']['numFound']).to eq 1

      doc = asset_results['response']['docs'].first
      expect(doc['id']).to eq asset1.id
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

  describe '#update' do
    before { sign_in user }

    context 'collection members' do
      before do
        [asset1, asset2].each do |asset|
          asset.member_of_collections << collection
          asset.save!
        end
      end

      # Collections are unordered by default, which disallows duplicates.
      xit 'appends members to the collection in order, allowing duplicates' do
        # TODO: Using size until count is fixed https://github.com/projecthydra-labs/activefedora-aggregation/issues/78
        expect {
          put :update, params: { id: collection,
                                 collection: { members: 'add' },
                                 batch_document_ids: [asset2.id, asset1.id]
                               }
        }.to change { collection.reload.members.size }.by(2)
        expect(response).to redirect_to routes.url_helpers.collection_path(collection)
        expect(assigns[:collection].members).to eq [asset1, asset2, asset2, asset1]

        asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{asset2.id}\""], fl: ['id'] }
        expect(asset_results['response']['numFound']).to eq 1

        doc = asset_results['response']['docs'].first
        expect(doc['id']).to eq asset2.id
      end

      it "adds members to the collection" do
        expect {
          put :update, params: { id: collection,
                                 collection: { members: 'add' },
                                 batch_document_ids: [asset4.id]
                               }
        }.to change { collection.reload.member_objects.size }.by(1)
        expect(response).to redirect_to routes.url_helpers.collection_path(collection)
        expect(assigns[:collection].member_objects).to match_array [asset1, asset2, asset4]

        asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{asset2.id}\""], fl: ['id'] }
        expect(asset_results['response']['numFound']).to eq 1

        doc = asset_results['response']['docs'].first
        expect(doc['id']).to eq asset2.id
      end

      it "removes members from the collection" do
        # TODO: Using size until count is fixed https://github.com/projecthydra-labs/activefedora-aggregation/issues/78
        expect {
          put :update, params: { id: collection,
                                 collection: { members: 'remove' },
                                 batch_document_ids: [asset2]
                               }
        }.to change { asset2.reload.member_of_collections.size }.by(-1)
        asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{asset2.id}\""], fl: ['id'] }
        expect(asset_results['response']['numFound']).to eq 1

        doc = asset_results['response']['docs'].first
        expect(doc['id']).to eq asset2.id
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

    context 'updating a collections metadata' do
      it 'saves the metadata' do
        put :update, params: { id: collection, collection: { creator: ['Emily'], visibility: 'open' } }
        collection.reload
        expect(collection.creator).to eq ['Emily']
        expect(collection.visibility).to eq 'open'
      end

      it 'removes blank strings from params before updating Collection metadata' do
        put :update, params: { id: collection, collection: collection_attrs.merge(creator: ['']) }
        expect(assigns[:collection].title).to eq ['My First Collection']
        expect(assigns[:collection].creator).to eq([])
      end
    end
  end

  describe '#show' do
    context 'when signed in' do
      before do
        sign_in user
        [asset1, asset2, asset3].map do |a|
          a.apply_depositor_metadata(user)
          a.save
        end
        [asset1, asset2, asset3].each do |asset|
          asset.member_of_collections = [collection]
          asset.save
        end
      end

      it 'returns the collection and its members' do
        get :show, params: { id: collection }
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of CurationConcerns::CollectionPresenter
        expect(assigns[:presenter].to_s).to eq 'Collection Title'
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
      end

      context 'when the q parameter is passed' do
        it 'loads the collection (paying no attention to the q param)' do
          get :show, params: { id: collection, q: 'no matches' }
          expect(response).to be_successful
          expect(assigns[:presenter]).to be_kind_of CurationConcerns::CollectionPresenter
          expect(assigns[:presenter].to_s).to eq 'Collection Title'
        end
      end

      context 'when the page parameter is passed' do
        it 'loads the collection (paying no attention to the page param)' do
          get :show, params: { id: collection, page: '2' }
          expect(response).to be_successful
          expect(assigns[:presenter]).to be_kind_of CurationConcerns::CollectionPresenter
          expect(assigns[:presenter].to_s).to eq 'Collection Title'
        end
      end
    end

    context 'not signed in' do
      before do
        collection.members = [asset1, asset2, asset3]
        collection.save
      end
      it 'forces me to log in' do
        get :show, params: { id: collection }
        expect(response).to redirect_to(main_app.new_user_session_path)
      end
    end
  end

  describe '#edit' do
    let!(:my_collection) { create(:collection, user: user) }

    before do
      # We expect to not see this collection in the list
      create(:collection, :public)
      sign_in user
    end

    it 'is successful' do
      get :edit, params: { id: collection }
      expect(flash[:notice]).to be_nil
      # a list of collections I can add items to:
      expect(assigns[:user_collections].map(&:id)).to match_array [collection.id,
                                                                   my_collection.id]
    end
  end
end
