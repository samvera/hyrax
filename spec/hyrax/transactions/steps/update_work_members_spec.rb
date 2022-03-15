# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::UpdateWorkMembers, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:listener) { Hyrax::Specs::SpyListener.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }

  before { Hyrax.publisher.subscribe(listener) }
  after  { Hyrax.publisher.unsubscribe(listener) }

  context 'with a blank work_members_attributes param' do
    it 'returns success' do
      expect(step.call(work)).to be_success
    end
  end

  context 'when adding a work member' do
    let(:child) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:attributes) { HashWithIndifferentAccess.new({ '0' => { id: child.id } }) }

    it 'adds member work' do
      expect { step.call(work, work_members_attributes: attributes) }
        .to change { Hyrax.query_service.custom_queries.find_child_works(resource: work) }
        .from(be_empty)
        .to contain_exactly(child)
    end

    it 'publishes a metadata change event for the work' do
      expect { step.call(work, work_members_attributes: attributes) }
        .to change { listener.object_metadata_updated&.payload }
        .to match object: be_a(Hyrax::Resource), user: nil
    end
  end

  context 'when removing a work member' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_works) }
    let(:children) { Hyrax.query_service.custom_queries.find_child_works(resource: work) }
    let(:child1) { children.first }
    let(:child2) { children.last }
    let(:attributes) { HashWithIndifferentAccess.new({ '0' => { id: child1.id, _destroy: 'true' } }) }

    it 'removes a member work' do
      expect { step.call(work, work_members_attributes: attributes) }
        .to change { Hyrax.query_service.custom_queries.find_child_works(resource: work) }
        .from([child1, child2])
        .to contain_exactly(child2)
    end
  end
end
