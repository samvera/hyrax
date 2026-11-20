# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::WorkDestroy do
  wings = !Hyrax.config.disable_wings

  subject(:transaction) { described_class.new }
  let(:work)      { FactoryBot.valkyrie_create(:hyrax_work, read_users: [user], members: [file_set]) }
  let(:file_set)  { FactoryBot.valkyrie_create(:hyrax_file_set) }

  describe '#call' do
    let(:user) { FactoryBot.create(:user) }

    context 'without a user' do
      it 'is a failure' do
        expect(transaction.call(work)).to be_failure
      end
    end

    it 'succeeds' do
      expect(transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work))
        .to be_success
    end

    it 'deletes the work' do
      transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work)

      expect { Hyrax.query_service.find_by(id: work.id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'deletes the file set' do
      transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work)

      expect { Hyrax.query_service.find_by(id: file_set.id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'deletes the access control resource' do
      expect { transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work) }
        .to change { Hyrax::AccessControl.for(resource: work).persisted? }
        .from(true).to(false)
    end

    context 'with several member file sets', index_adapter: :solr_index do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_file_sets) }
      let(:destroy_work) do
        transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user },
                                   'work_resource.delete' => { user: user })
      end

      before do
        Hyrax.index_adapter.save(resource: work)
        FactoryBot.create(:sipity_entity, proxy_for_global_id: Hyrax::ValkyrieGlobalIdProxy.new(resource: work).to_global_id.to_s)
      end

      it 'does not publish a metadata update for the work' do
        allow(Hyrax.publisher).to receive(:publish).and_call_original
        expect(Hyrax.publisher).not_to receive(:publish)
          .with('object.metadata.updated', hash_including(object: having_attributes(id: work.id)))

        destroy_work.call(work)
      end

      it 'does not queue a content update event for the work' do
        expect { destroy_work.call(work) }.not_to have_enqueued_job(ContentUpdateEventJob)
      end

      it 'removes the work from the index' do
        expect { destroy_work.call(work) }
          .to change { Hyrax::SolrService.count("id:#{work.id}") }.from(1).to(0)
      end

      it 'removes the workflow entity for the work' do
        expect { destroy_work.call(work) }.to change { Sipity::Entity.count }.by(-1)
      end
    end

    context "with attached files" do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, uploaded_files: [FactoryBot.create(:uploaded_file)], edit_users: [user]) }
      let(:file_set) { query_service.find_members(resource: work).first }
      let(:file_metadata) { query_service.custom_queries.find_files(file_set: file_set).first }
      let(:uploaded) { storage_adapter.find_by(id: file_metadata.file_identifier) }
      let(:storage_adapter) { Hyrax.storage_adapter }
      let(:query_service) { Hyrax.query_service }
      it "deletes them" do
        file_metadata
        transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work)

        expect { Hyrax.query_service.find_by(id: file_metadata.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
        expect { storage_adapter.find_by(id: uploaded.id) }.to raise_error Valkyrie::StorageAdapter::FileNotFound
      end
    end

    context 'when a step fails after file sets are destroyed' do
      let(:work) do
        work = FactoryBot.valkyrie_create(:hyrax_work, :with_member_file_sets)
        work.thumbnail_id = work.member_ids.first
        work.representative_id = work.member_ids.first
        Hyrax.persister.save(resource: work)
      end
      let(:destroy_work) { transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }) }
      let(:surviving_work) { Hyrax.query_service.find_by(id: work.id) }

      shared_examples 'it removes the destroyed file sets from the surviving work' do
        it 'fails and leaves the work without references to them' do
          expect(destroy_work.call(work)).to be_failure

          expect(surviving_work.member_ids).to be_empty
          expect(surviving_work.thumbnail_id).to be_nil
          expect(surviving_work.representative_id).to be_nil
        end
      end

      context 'because deleting the access control fails' do
        before do
          allow(Hyrax::Transactions::Container).to receive(:[]).and_call_original
          allow(Hyrax::Transactions::Container).to receive(:[]).with('work_resource.delete_acl')
                                                               .and_return(->(_work) { Dry::Monads::Failure(:failed) })
        end

        it_behaves_like 'it removes the destroyed file sets from the surviving work'
      end

      context 'because removing redirect paths fails' do
        before do
          allow_any_instance_of(Hyrax::Transactions::Steps::RemoveRedirectPaths)
            .to receive(:call).and_return(Dry::Monads::Failure(:failed))
        end

        it_behaves_like 'it removes the destroyed file sets from the surviving work'
      end

      context 'because a later file set fails to delete' do
        let(:failing_id) { work.member_ids.last }
        let(:spy_listener) { Hyrax::Specs::SpyListener.new }

        before do
          allow_any_instance_of(Hyrax::Transactions::FileSetDestroy)
            .to receive(:call).and_wrap_original do |original, file_set|
              file_set.id == failing_id ? Dry::Monads::Failure(:failed) : original.call(file_set)
            end
          Hyrax.publisher.subscribe(spy_listener)
        end
        after { Hyrax.publisher.unsubscribe(spy_listener) }

        it 'keeps only the file set that was not destroyed' do
          expect(destroy_work.call(work)).to be_failure

          expect(surviving_work.member_ids).to eq [failing_id]
          expect(surviving_work.thumbnail_id).to be_nil
          expect(surviving_work.representative_id).to be_nil
        end

        it 'publishes a metadata update for the repaired work', unless: wings do
          destroy_work.call(work)

          expect(spy_listener.object_metadata_updated&.payload).to include(object: having_attributes(id: work.id), user: user)
        end
      end
    end
  end
end
