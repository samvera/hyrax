describe 'routing and paths', type: :routing do
  routes { Sufia::Engine.routes }

  let(:item_id) { '123' }

  describe 'Arkivo' do
    context 'with a constraint defined' do
      before do
        allow(Sufia::ArkivoConstraint).to receive(:matches?) { false }
      end

      it 'does not recognize routes' do
        expect(post: '/api/items').not_to be_routable
      end
    end

    context 'without a constraint defined' do
      before do
        allow(Sufia::ArkivoConstraint).to receive(:matches?) { true }
      end

      it 'routes POSTs to the items resource' do
        expect(post: '/api/items').to route_to(controller: 'api/items', action: 'create', format: :json)
      end

      it 'does not route GETs to the items resource' do
        expect(get: '/api/items').not_to route_to(controller: 'api/items', action: 'index', format: :json)
      end

      it 'does not route DELETEs to the items resource' do
        expect(delete: '/api/items').not_to route_to(controller: 'api/items', action: 'destroy', format: :json)
      end

      it 'does not route PUTs to the items resource' do
        expect(put: '/api/items').not_to route_to(controller: 'api/items', action: 'update', format: :json)
      end

      it 'does not route PATCHes to the items resource' do
        expect(patch: '/api/items').not_to route_to(controller: 'api/items', action: 'update', format: :json)
      end

      context 'with a member resource' do
        subject { "/api/items/#{item_id}" }

        it 'routes GETs to an item resource' do
          expect(get: subject).to route_to(controller: 'api/items', action: 'show', id: item_id, format: :json)
        end

        it 'routes PUTs to an item resource' do
          expect(put: subject).to route_to(controller: 'api/items', action: 'update', id: item_id, format: :json)
        end

        it 'routes DELETEs to an item resource' do
          expect(delete: subject).to route_to(controller: 'api/items', action: 'destroy', id: item_id, format: :json)
        end
      end
    end
  end

  describe 'Zotero' do
    it 'routes GETs to the zotero resource' do
      expect(get: '/api/zotero').to route_to(controller: 'api/zotero', action: 'initiate')
    end
  end

  describe 'Zotero callbacks' do
    it 'routes GETs to the callback resource' do
      expect(get: '/api/zotero/callback').to route_to(controller: 'api/zotero', action: 'callback')
    end
  end

  describe 'path helpers' do
    it 'has a path for creating new items' do
      expect(api_items_path).to eq '/api/items'
    end

    it 'has a path for operating on existing items' do
      expect(api_item_path(item_id)).to eq "/api/items/#{item_id}"
    end

    it 'has a path for initiating Zotero authentication' do
      expect(api_zotero_initiate_path).to eq '/api/zotero'
    end

    it 'has a path for Zotero authN callbacks' do
      expect(api_zotero_callback_path).to eq '/api/zotero/callback'
    end
  end
end
