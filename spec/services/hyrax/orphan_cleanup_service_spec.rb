# frozen_string_literal: true

RSpec.describe Hyrax::OrphanCleanupService, index_adapter: :solr_index do
  wings = !Hyrax.config.disable_wings

  subject(:service) { described_class.new(delete: delete, min_age: 0.seconds) }
  let(:delete) { false }

  let!(:work) { FactoryBot.valkyrie_create(:monograph, :with_member_file_sets) }
  let!(:orphan_file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let!(:deleted_work) { FactoryBot.valkyrie_create(:monograph) }

  before do
    Hyrax.index_adapter.wipe!
    Hyrax.persister.delete(resource: deleted_work)
    [work, orphan_file_set, deleted_work, *Hyrax.query_service.find_members(resource: work)].each do |resource|
      Hyrax.index_adapter.save(resource: resource)
    end
  end

  def indexed?(id)
    Hyrax::SolrService.count("id:#{id}").positive?
  end

  describe '#call' do
    context 'with a query service that reads through Wings', if: wings, valkyrie_adapter: :freyja_adapter do
      let(:delete) { true }

      it 'skips the file set scan, because Wings finds parents through Solr' do
        expect(Hyrax.logger).to receive(:warn).with(/Wings/)

        expect(service.call[:file_set_ids]).to be_empty
        expect(Hyrax.query_service.find_by(id: orphan_file_set.id)).to be_present
      end
    end

    context 'with the Wings query service', if: wings do
      let(:delete) { true }

      it 'skips the file set scan, because Wings finds parents through Solr' do
        expect(Hyrax.logger).to receive(:warn).with(/Wings/)

        expect(service.call[:file_set_ids]).to be_empty
        expect(Hyrax.query_service.find_by(id: orphan_file_set.id)).to be_present
      end
    end

    it 'reports file sets that belong to no work', unless: wings do
      file_set_ids = service.call[:file_set_ids]

      expect(file_set_ids).to include(orphan_file_set.id.to_s)
      expect(file_set_ids).not_to include(*work.member_ids.map(&:to_s))
    end

    it 'checks parents only for file sets that no work lists', unless: wings do
      query_service = Hyrax.query_service
      allow(Hyrax).to receive(:query_service).and_return(query_service)
      allow(query_service).to receive(:find_parents).and_call_original

      service.call

      expect(query_service).to have_received(:find_parents).with(resource: having_attributes(id: orphan_file_set.id))
      work.member_ids.each do |id|
        expect(query_service).not_to have_received(:find_parents).with(resource: having_attributes(id: id))
      end
    end

    it 'confirms candidates whose work type the bulk scan does not cover', unless: wings do
      allow(Hyrax::ModelRegistry).to receive(:work_classes).and_return([])

      expect(service.call[:file_set_ids]).not_to include(*work.member_ids.map(&:to_s))
    end

    it 'skips file sets changed too recently to rule out an upload in progress' do
      expect(described_class.new.call[:file_set_ids]).not_to include(orphan_file_set.id.to_s)
    end

    it 'reports index documents for objects no longer in the repository' do
      expect(service.call[:index_ids]).to contain_exactly(deleted_work.id.to_s)
    end

    it 'reports them across several batches' do
      stub_const("#{described_class}::BATCH_SIZE", 1)

      expect(service.call[:index_ids]).to contain_exactly(deleted_work.id.to_s)
    end

    it 'deletes nothing in a dry run' do
      service.call

      expect(Hyrax.query_service.find_by(id: orphan_file_set.id)).to be_present
      expect(indexed?(deleted_work.id)).to be true
    end

    context 'when deleting' do
      let(:delete) { true }

      it 'destroys the orphaned file sets', unless: wings do
        service.call

        expect { Hyrax.query_service.find_by(id: orphan_file_set.id) }
          .to raise_error Valkyrie::Persistence::ObjectNotFoundError
        expect(indexed?(orphan_file_set.id)).to be false
      end

      it 'removes the stray index documents' do
        expect { service.call }.to change { indexed?(deleted_work.id) }.from(true).to(false)
      end

      context 'when an orphaned file set cannot be destroyed', unless: wings do
        before do
          allow_any_instance_of(Hyrax::Transactions::FileSetDestroy)
            .to receive(:call).and_return(Dry::Monads::Failure(:failed))
        end

        it 'reports it as failed rather than removed' do
          result = service.call

          expect(result[:failed_file_set_ids]).to include(orphan_file_set.id.to_s)
          expect(result[:file_set_ids]).not_to include(orphan_file_set.id.to_s)
        end
      end

      it 'leaves the work and its file sets alone' do
        service.call

        expect(Hyrax.query_service.find_by(id: work.id).member_ids).to all(be_present)
        expect(Hyrax.query_service.find_many_by_ids(ids: work.member_ids).count).to eq 2
        expect(indexed?(work.id)).to be true
      end
    end
  end
end
