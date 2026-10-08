# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::RemoveFromMembership, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:user)         { FactoryBot.create(:user) }
  let(:collection)   { FactoryBot.valkyrie_create(:hyrax_collection) }
  let(:work)         { FactoryBot.valkyrie_create(:monograph, member_of_collection_ids: [collection.id]) }
  let(:spy_listener) { Hyrax::Specs::SpyListener.new }

  describe '#call' do
    before do
      work
      Hyrax.publisher.subscribe(spy_listener)
    end
    after { Hyrax.publisher.unsubscribe(spy_listener) }

    it 'fails without a user' do
      expect(step.call(collection)).to be_failure
    end

    it 'gives success' do
      expect(step.call(collection, user: user)).to be_success
    end

    it 'removes collection references from member objects' do
      expect { step.call(collection, user: user) }
        .to change { Hyrax.custom_queries.find_members_of(collection: collection).size }
        .from(1)
        .to(0)
    end

    context 'when the member is indexed', index_adapter: :solr_index do
      before { Hyrax.index_adapter.save(resource: work) }

      it 're-indexes the member without the collection' do
        indexed_collection_ids = lambda do
          Hyrax::SolrService.query("id:#{work.id}", fl: 'member_of_collection_ids_ssim', rows: 1).first['member_of_collection_ids_ssim']
        end

        expect { step.call(collection, user: user) }
          .to change(&indexed_collection_ids).from([collection.id.to_s]).to(nil)
      end
    end

    context 'when re-indexing a member fails' do
      before do
        allow(Hyrax.publisher).to receive(:publish).and_call_original
        allow(Hyrax.publisher).to receive(:publish).with('object.membership.updated', any_args).and_raise(StandardError, 'Solr unavailable')
        allow(Hyrax.logger).to receive(:error)
      end

      it 'logs the member and still succeeds' do
        expect(step.call(collection, user: user)).to be_success
        expect(Hyrax.logger).to have_received(:error).with(/#{work.id}/)
      end
    end

    it 'publishes events' do
      expect { step.call(collection, user: user) }
        .to change { spy_listener.collection_membership_updated&.payload }
        .to match(collection: collection, user: user)
    end
  end
end
