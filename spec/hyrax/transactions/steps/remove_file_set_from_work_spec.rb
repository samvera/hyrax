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

      context 'and an adapter other than the default' do
        subject(:step) { described_class.new(query_service: adapter.query_service, persister: adapter.persister) }
        let(:adapter) { Valkyrie::Persistence::Memory::MetadataAdapter.new }
        let(:file_set) { adapter.persister.save(resource: Hyrax::FileSet.new) }
        let!(:work) { adapter.persister.save(resource: Hyrax::Test::SimpleWork.new(member_ids: [file_set.id])) }

        it 'removes the file set from the parent in that adapter' do
          step.call(file_set, user: user)

          expect(adapter.query_service.find_by(id: work.id).member_ids).to be_empty
        end
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

        context 'when another process added a member to the work after this step read it' do
          let(:other_member) { FactoryBot.valkyrie_create(:hyrax_work) }

          before do
            other_member
            allow(Hyrax.query_service).to receive(:find_parents).and_wrap_original do |original, resource:|
              parents = original.call(resource: resource).to_a
              save_work_elsewhere(work.id) { |stored| stored.member_ids += [other_member.id] }
              parents
            end
          end

          it 'keeps that member' do
            step.call(file_set, user: user)

            member_ids = Hyrax.query_service.find_by(id: work.id).member_ids
            expect(member_ids).to include(other_member.id)
            expect(member_ids).not_to include(file_set.id)
          end
        end

        context 'when another process chose a new representative and thumbnail after this step read the work' do
          let(:file_set) { Hyrax.query_service.custom_queries.find_child_file_sets(resource: work).to_a.last }
          let(:new_default) { FactoryBot.valkyrie_create(:hyrax_file_set) }

          before do
            new_default
            allow(Hyrax.query_service).to receive(:find_parents).and_wrap_original do |original, resource:|
              parents = original.call(resource: resource).to_a
              save_work_elsewhere(work.id) do |stored|
                stored.member_ids += [new_default.id]
                stored.representative_id = new_default.id
                stored.thumbnail_id = new_default.id
              end
              parents
            end
          end

          it 'keeps them' do
            step.call(file_set, user: user)

            expect(Hyrax.query_service.find_by(id: work.id))
              .to have_attributes(representative_id: new_default.id, thumbnail_id: new_default.id)
          end
        end
      end
    end
  end
end
