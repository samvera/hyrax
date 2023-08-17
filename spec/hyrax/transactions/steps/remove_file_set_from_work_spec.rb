# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/add_to_collections'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::RemoveFileSetFromWork, valkyrie_adapter: :test_adapter do
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
        let(:work) do
          FactoryBot.valkyrie_create(:hyrax_work,
                                     :with_member_file_sets,
                                     :with_representative,
                                     :with_thumbnail,
                                     :with_renderings)
        end
        let(:file_set) { Hyrax.query_service.custom_queries.find_child_file_sets(resource: work).first }
        let(:parent) { Hyrax.query_service.find_parents(resource: file_set).first }
        let(:listener) { Hyrax::Specs::SpyListener.new }

        before { Hyrax.publisher.subscribe(listener) }
        after  { Hyrax.publisher.unsubscribe(listener) }

        it 'removes the file set from the parent' do
          expect { step.call(file_set, user: user) }
            .to change { Hyrax.query_service.find_parents(resource: file_set).to_a }
            .to be_empty
        end

        describe 'it unlinks the file set from the parent' do
          it 'by clearing representative_id' do
            expect { step.call(file_set, user: user) }
              .to change { Hyrax.query_service.find_by(id: parent.id).representative_id }
              .to be_nil
          end

          it 'by clearing thumbnail_id' do
            expect { step.call(file_set, user: user) }
              .to change { Hyrax.query_service.find_by(id: parent.id).thumbnail_id }
              .to be_nil
          end

          it 'by deleting from rendering_ids' do
            expect { step.call(file_set, user: user) }
              .to change { Hyrax.query_service.find_by(id: parent.id).rendering_ids }
              .to be_empty
          end
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
