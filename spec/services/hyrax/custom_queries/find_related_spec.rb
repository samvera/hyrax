# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::FindRelated do
  let(:metadata_adapter) { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:query_service) { metadata_adapter.query_service }
  let(:persister) { metadata_adapter.persister }

  before do
    query_service.custom_queries.register_query_handler(described_class)
    module Hyrax::Test::FindRelated
      class Work < Valkyrie::Resource
        attribute :child_work_ids, Valkyrie::Types::Set
        attribute :child_file_set_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
      end
      class FileSet < Valkyrie::Resource; end
    end
    # Hyrax::Test::FindRelated::Work
    # Hyrax::Test::FindRelated::FileSet
  end

  after { Hyrax::Test.send(:remove_const, :FindRelated) }

  let(:fileset_id1) { Valkyrie::ID.new'fs1' }
  let(:fileset_id2) { Valkyrie::ID.new'fs2' }
  let(:fileset1) { persister.save(resource: Hyrax::Test::FindRelated::FileSet.new(id: fileset_id1)) }
  let(:fileset2) { persister.save(resource: Hyrax::Test::FindRelated::FileSet.new(id: fileset_id2)) }

  let(:work_id1) { Valkyrie::ID.new'wk1' }
  let(:work_id2) { Valkyrie::ID.new'wk2' }
  let(:work1) do
    persister.save(resource:
      Hyrax::Test::FindRelated::Work.new.tap do |w|
        w.id = work_id1
        w.child_work_ids = [work_id2, 'NOT_AN_ID']
        w.child_file_set_ids = [fileset_id1, fileset_id2]
      end)
  end
  let(:work2) { persister.save(resource: Hyrax::Test::FindRelated::Work.new(id: work_id2)) }

  describe '.find_related_ids_for' do
    context 'when all values for the relationship are ids' do
      subject { query_service.custom_queries.find_related_ids_for(resource: work1, relationship: :child_file_set_ids) }
      before do
        fileset1
        fileset2
      end
      it 'returns all related' do
        expect(subject).to contain_exactly(fileset_id1, fileset_id2)
      end
    end

    context 'when mix of ids and other types for the relationship' do
      subject { query_service.custom_queries.find_related_ids_for(resource: work1, relationship: :child_work_ids) }
      before { work2 }
      it 'returns only related values that are ids' do
        expect(subject).to contain_exactly(work_id2)
      end
    end
  end

  describe '.find_related_for' do
    context 'when all values for the relationship are ids' do
      subject { query_service.custom_queries.find_related_for(resource: work1, relationship: :child_file_set_ids) }
      before do
        fileset1
        fileset2
      end
      it 'returns all related' do
        expect(subject.map(&:class).first).to eq(Hyrax::Test::FindRelated::FileSet)
        expect(subject.map(&:id)).to contain_exactly(fileset_id1, fileset_id2)
      end
    end

    context 'when mix of ids and other types for the relationship' do
      subject { query_service.custom_queries.find_related_for(resource: work1, relationship: :child_work_ids) }
      before { work2 }
      it 'returns only related values that are ids' do
        expect(subject.map(&:class).first).to eq(Hyrax::Test::FindRelated::Work)
        expect(subject.map(&:id)).to contain_exactly(work_id2)
      end
    end
  end
end
