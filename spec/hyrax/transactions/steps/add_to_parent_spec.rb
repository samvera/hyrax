# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::AddToParent, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:listener) { Hyrax::Specs::SpyListener.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }

  before { Hyrax.publisher.subscribe(listener) }
  after  { Hyrax.publisher.unsubscribe(listener) }

  it 'gives success' do
    expect(step.call(work)).to be_success
  end

  context 'when the parent does not exist' do
    it 'is a failure' do
      expect(step.call(work, parent_id: 'NOT_A_REAL_ID'))
        .to be_failure
    end
  end

  context 'with a valid parent id' do
    let(:parent) { FactoryBot.valkyrie_create(:hyrax_work) }

    it 'is a success' do
      expect(step.call(work, parent_id: parent.id))
        .to be_success
    end

    it 'adds work to parent work' do
      expect { step.call(work, parent_id: parent.id) }
        .to change { Hyrax.query_service.custom_queries.find_child_works(resource: parent) }
        .from(be_empty)
        .to contain_exactly(work)
    end

    it 'publishes a metadata change event for the parent work' do
      expect { step.call(work, parent_id: parent.id) }
        .to change { listener.object_metadata_updated&.payload }
        .to match(object: parent, user: nil)
    end
  end
end
