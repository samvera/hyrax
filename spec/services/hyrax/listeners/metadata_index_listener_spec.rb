# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::MetadataIndexListener do
  subject(:listener) { described_class.new }
  let(:data)         { { object: resource } }
  let(:event)        { Dry::Events::Event.new(event_type, data) }
  let(:fake_adapter) { FakeIndexingAdapter.new }
  let(:resource)     { FactoryBot.valkyrie_create(:hyrax_resource) }

  let(:skipping_message) { /Skipping (object|collection) reindex because the (object|collection) .*/ }

  # the listener should always use the currently configured Hyrax Index Adapter
  before do
    allow(Hyrax).to receive(:index_adapter).and_return(fake_adapter)
  end

  describe '#on_object_deleted' do
    let(:event_type) { :on_object_deleted }

    it 'reindexes the object on the configured adapter' do
      expect(Hyrax.logger).not_to receive(:info).with(skipping_message)
      expect { listener.on_object_deleted(event) }
        .to change { fake_adapter.deleted_resources }
        .to contain_exactly(resource)
    end

    context 'when it gets a non-resource as payload' do
      let(:resource) { ActiveFedora::Base.new }

      it 'returns as a no-op' do
        expect(Hyrax.logger).to receive(:info).with(skipping_message)
        expect { listener.on_object_deleted(event) }
          .not_to change { fake_adapter.deleted_resources }
      end
    end
  end

  describe '#on_object_membership_updated' do
    let(:event_type) { :on_object_membership_updated }

    it 'reindexes the object on the configured adapter' do
      expect { listener.on_object_membership_updated(event) }
        .to change { fake_adapter.saved_resources }
        .to contain_exactly(resource)
    end

    it 'reindexes the object from ID on the configured adapter' do
      data  = { object_id: resource.id }
      event = Dry::Events::Event.new(event_type, data)

      expect { listener.on_object_membership_updated(event) }
        .to change { fake_adapter.saved_resources }
        .to contain_exactly(resource)
    end

    context 'when the resource does not exist' do
      let(:data) { { object_id: 'MISSING_ID_FOR_METADATA_INDEX_LISTENER_SPEC' } }

      it 'does not raise' do
        expect { listener.on_object_membership_updated(event) }
          .not_to raise_error
      end

      it 'logs failure' do
        expect(Hyrax.logger)
          .to receive(:error)
          .with(/MISSING_ID_FOR_METADATA_INDEX_LISTENER_SPEC/)

        listener.on_object_membership_updated(event)
      end
    end
  end

  describe '#on_object_metadata_updated' do
    let(:event_type) { :on_object_metadata_updated }

    it 'reindexes the object on the configured adapter' do
      expect(Hyrax.logger).not_to receive(:info).with(skipping_message)
      expect { listener.on_object_metadata_updated(event) }
        .to change { fake_adapter.saved_resources }
        .to contain_exactly(resource)
    end

    context 'when it gets a non-resource as payload' do
      let(:resource) { ActiveFedora::Base.new }

      it 'returns as a no-op' do
        expect(Hyrax.logger).to receive(:info).with(skipping_message)
        expect { listener.on_object_metadata_updated(event) }
          .not_to change { fake_adapter.saved_resources }
      end
    end

    context 'when the object is a file set used as a work thumbnail',
            :valkyrie_metadata_adapter, skip: !Hyrax.config.disable_wings do
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
      let(:work)     { FactoryBot.valkyrie_create(:hyrax_work, thumbnail_id: file_set.id) }
      let(:data)     { { object: file_set } }

      before { work } # ensure work is persisted

      it 'also reindexes the parent work' do
        allow(Hyrax.custom_queries).to receive(:find_parent_work).with(resource: file_set).and_return(work)
        expect { listener.on_object_metadata_updated(event) }
          .to change { fake_adapter.saved_resources }
          .to include(file_set, work)
      end

      context 'when the file set is not the thumbnail' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

        it 'does not reindex the parent work' do
          allow(Hyrax.custom_queries).to receive(:find_parent_work).with(resource: file_set).and_return(work)
          expect { listener.on_object_metadata_updated(event) }
            .to change { fake_adapter.saved_resources }
            .to contain_exactly(file_set)
        end
      end

      context 'when the parent work is not found' do
        it 'does not raise' do
          allow(Hyrax.custom_queries).to receive(:find_parent_work)
            .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
          expect { listener.on_object_metadata_updated(event) }.not_to raise_error
        end
      end
    end
  end

  describe '#on_collection_deleted' do
    let(:event_type) { :on_collection_deleted }
    let(:resource)   { FactoryBot.valkyrie_create(:hyrax_collection) }
    let(:data)       { { collection: resource } }

    it 'reindexes the collection on the configured adapter' do
      expect(Hyrax.logger).not_to receive(:info).with(skipping_message)
      expect { listener.on_collection_deleted(event) }
        .to change { fake_adapter.deleted_resources }
        .to contain_exactly(resource)
    end

    context 'when it gets a non-resource as payload' do
      let(:resource) { ActiveFedora::Base.new }

      it 'returns as a no-op' do
        expect(Hyrax.logger).to receive(:info).with(skipping_message)
        expect { listener.on_collection_deleted(event) }
          .not_to change { fake_adapter.deleted_resources }
      end
    end
  end

  describe '#on_collection_metadata_updated' do
    let(:event_type) { :on_collection_metadata_updated }
    let(:data)       { { collection: resource } }

    it 'reindexes the collection on the configured adapter' do
      expect(Hyrax.logger).not_to receive(:info).with(skipping_message)
      expect { listener.on_collection_metadata_updated(event) }
        .to change { fake_adapter.saved_resources }
        .to contain_exactly(resource)
    end

    context 'when it gets a non-resource as payload' do
      let(:resource) { ActiveFedora::Base.new }

      it 'returns as a no-op' do
        expect(Hyrax.logger).to receive(:info).with(skipping_message)
        expect { listener.on_collection_metadata_updated(event) }
          .not_to change { fake_adapter.saved_resources }
      end
    end
  end
end
