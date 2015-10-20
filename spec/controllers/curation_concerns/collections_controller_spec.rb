require 'spec_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end

  let(:user) { FactoryGirl.create(:user) }
  let(:asset1) { FactoryGirl.build(:generic_work, title: ['First of the Assets'], user: user) }
  let(:asset2) { FactoryGirl.build(:generic_work, title: ['Second of the Assets'], user: user, depositor: user.user_key) }
  let(:asset3) { FactoryGirl.build(:generic_work, title: ['Third of the Assets']) }
  let!(:asset4) { FactoryGirl.create(:generic_work, title: ['Fourth of the Assets'], user: user) }
  let(:bogus_depositor_asset) { FactoryGirl.create(:generic_work, title: ['Bogus Asset'], depositor: 'abc') }
  let(:collection_attrs) { FactoryGirl.attributes_for(:collection, title: 'My First Collection ', description: "The Description\r\n\r\nand more") }
  let(:collection) { FactoryGirl.create(:collection, title: 'Collection Title', user: user) }

  describe '#new' do
    before do
      sign_in user
    end

    it 'assigns @collection' do
      get :new
      expect(assigns(:collection)).to be_kind_of(Collection)
    end
  end

  describe '#create' do
    before do
      sign_in user
    end

    it 'creates a Collection' do
      expect do
        post :create, collection: collection_attrs.merge(visibility: 'open')
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].visibility).to eq 'open'
    end

    it 'removes blank strings from params before creating Collection' do
      expect do
        post :create, collection: collection_attrs.merge(creator: [''])
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].title).to eq('My First Collection ')
      expect(assigns[:collection].creator).to eq([])
    end

    it 'creates a Collection with files I can access' do
      [asset1, asset2].map(&:save) # bogus_depositor_asset is already saved
      expect do
        post :create, collection: collection_attrs,
                      batch_document_ids: [asset1.id, asset2.id, bogus_depositor_asset.id]
      end.to change { Collection.count }.by(1)
      collection = assigns(:collection)
      expect(collection.members).to match_array [asset1, asset2]
    end

    it 'adds docs to the collection if a batch id is provided and add the collection id to the documents in the collection' do
      asset1.save
      post :create, batch_document_ids: [asset1.id], collection: collection_attrs
      expect(assigns[:collection].members).to eq [asset1]

      asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{asset1.id}\""], fl: ['id'] }
      expect(asset_results['response']['numFound']).to eq 1

      doc = asset_results['response']['docs'].first
      expect(doc['id']).to eq asset1.id
    end
  end

  describe '#update' do
    before { sign_in user }

    context 'collection members' do
      before do
        [asset1, asset2].map(&:save) # bogus_depositor_asset is already saved
        collection.members = [asset1, asset2]
        collection.save!
      end

      # Collections are unordered by default, which disallows duplicates.
      xit 'appends members to the collection in order, allowing duplicates' do
        # TODO: Using size until count is fixed https://github.com/projecthydra-labs/activefedora-aggregation/issues/78
        expect {
          put :update, id: collection,
                       collection: { members: 'add' },
                       batch_document_ids: [asset2.id, asset1.id]
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
          put :update, id: collection,
                       collection: { members: 'add' },
                       batch_document_ids: [asset4.id]
        }.to change { collection.reload.members.size }.by(1)
        expect(response).to redirect_to routes.url_helpers.collection_path(collection)
        expect(assigns[:collection].members).to eq [asset1, asset2, asset4]

        asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{asset2.id}\""], fl: ['id'] }
        expect(asset_results['response']['numFound']).to eq 1

        doc = asset_results['response']['docs'].first
        expect(doc['id']).to eq asset2.id
      end

      it "removes members from the collection" do
        # TODO: Using size until count is fixed https://github.com/projecthydra-labs/activefedora-aggregation/issues/78
        expect {
          put :update, id: collection,
                       collection: { members: 'remove' },
                       batch_document_ids: [asset2]
        }.to change { collection.reload.members.size }.by(-1)
        asset_results = ActiveFedora::SolrService.instance.conn.get 'select', params: { fq: ["id:\"#{asset2.id}\""], fl: ['id'] }
        expect(asset_results['response']['numFound']).to eq 1

        doc = asset_results['response']['docs'].first
        expect(doc['id']).to eq asset2.id
      end
    end

    context 'updating a collections metadata' do
      it 'saves the metadata' do
        put :update, id: collection, collection: { creator: ['Emily'], visibility: 'open' }
        collection.reload
        expect(collection.creator).to eq ['Emily']
        expect(collection.visibility).to eq 'open'
      end

      it 'removes blank strings from params before updating Collection metadata' do
        put :update, id: collection, collection: collection_attrs.merge(creator: [''])
        expect(assigns[:collection].title).to eq('My First Collection ')
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
        collection.members = [asset1, asset2, asset3]
        collection.save
      end

      it 'returns the collection and its members' do
        get :show, id: collection
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of CurationConcerns::CollectionPresenter
        expect(assigns[:presenter].title).to eq collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
      end
    end

    context 'not signed in' do
      before do
        collection.members = [asset1, asset2, asset3]
        collection.save
      end
      it 'forces me to log in' do
        get :show, id: collection
        expect(response).to redirect_to(main_app.new_user_session_path)
      end
    end
  end

  describe '#edit' do
    before { sign_in user }

    it 'does not show flash' do
      get :edit, id: collection
      expect(flash[:notice]).to be_nil
    end
  end
end
