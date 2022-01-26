# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::FileMetadataListener, valkyrie_adapter: :test_adapter do
  subject(:listener) { described_class.new }
  let(:data)         { { metadata: metadata, user: user } }
  let(:event)        { Dry::Events::Event.new(event_type, data) }
  let(:fake_adapter) { FakeIndexingAdapter.new }
  let(:file_set)     { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let(:metadata)     { FactoryBot.valkyrie_create(:hyrax_file_metadata, file_set_id: file_set.id) }
  let(:user)         { FactoryBot.create(:user) }

  # the listener always uses the currently configured Hyrax Index Adapter
  before do
    allow(Hyrax).to receive(:index_adapter).and_return(fake_adapter)
  end

  describe '#on_file_metadata_updated' do
    let(:event_type) { :on_file_metadata_updated }

    it 'indexes the file_set' do
      expect { listener.on_file_metadata_updated(event) }
        .to change { fake_adapter.saved_resources }
        .from(be_empty)
        .to contain_exactly(file_set)
    end

    context 'when the file is not in a file set' do
      let(:metadata) do
        FactoryBot.valkyrie_create(:hyrax_file_metadata)
      end

      it 'does not index the file_set' do
        expect { listener.on_file_metadata_updated(event) }
          .not_to change { fake_adapter.saved_resources }
          .from(be_empty)
      end

      it 'logs the unexpected message' do
        expect(Hyrax.logger)
          .to receive(:warn)
          .with(/#{metadata.id}/)
      end
    end

    context 'when the file is not an original file' do
      let(:metadata) do
        FactoryBot.valkyrie_create(:hyrax_file_metadata,
                                   file_set_id: file_set.id,
                                   type: Hyrax::FileMetadata::Use::THUMBNAIL)
      end

      it 'does not index the file_set' do
        expect { listener.on_file_metadata_updated(event) }
          .not_to change { fake_adapter.saved_resources }
          .from(be_empty)
      end
    end
  end
end
