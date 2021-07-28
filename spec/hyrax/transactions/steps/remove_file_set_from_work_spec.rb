# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/add_to_collections'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::RemoveFileSetFromWork do
  subject(:step) { described_class.new }
  let(:file_set) { FactoryBot.build(:hyrax_file_set) }

  describe '#call' do
    it 'is a Failure' do
      expect(step.call(file_set)).to be_failure
    end

    context 'with a user' do
      let(:user) { FactoryBot.create(:user) }

      it 'succeeds' do
        expect(step.call(file_set, user: user)).to be_success
      end

      context 'and with a parent' do
        let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :in_work) }
        let(:listener) { Hyrax::Specs::SpyListener.new }

        before { Hyrax.publisher.subscribe(listener) }
        after  { Hyrax.publisher.unsubscribe(listener) }

        it 'removes the file set from the parent' do
          expect { step.call(file_set, user: user) }
            .to change { Hyrax.query_service.find_parents(resource: file_set).to_a }
            .to be_empty
        end

        it 'publishes an update of the parent' do
          expect { step.call(file_set, user: user) }
            .to change { listener.object_metadata_updated&.payload }
            .to match object: be_a(Hyrax::Resource), user: user
        end
      end
    end
  end
end
