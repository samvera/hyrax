# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::ACLIndexListener do
  subject(:listener) { described_class.new }
  let(:acl)          { Hyrax::AccessControlList.new(resource: resource) }
  let(:data)         { { result: result, resource: resource, acl: acl } }
  let(:event)        { Dry::Events::Event.new(event_type, data) }
  let(:fake_adapter) { FakeIndexingAdapter.new }
  let(:result)       { :success }
  let(:resource)     { FactoryBot.valkyrie_create(:hyrax_resource) }

  # the listener always uses the currently configured Hyrax Index Adapter
  before do
    allow(Hyrax).to receive(:index_adapter).and_return(fake_adapter)
  end

  describe '#on_object_acl_updated' do
    let(:event_type) { :on_object_acl_updated }

    it 'reindexes the object on the configured adapter' do
      expect { listener.on_object_acl_updated(event) }
        .to change { fake_adapter.saved_resources }
        .to contain_exactly(resource)
    end

    context 'on failure' do
      let(:result) { :failure }

      it 'does not reindex the object' do
        expect { listener.on_object_acl_updated(event) }.not_to raise_error
      end
    end
  end
end
