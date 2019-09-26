# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::FindRelated do
  let(:metadata_adapter) { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:query_service) { metadata_adapter.query_service }
  let(:persister) { metadata_adapter.persister }

  before do
    query_service.custom_queries.register_query_handler(described_class)
    module Hyrax::Test::FindRelated
      class Collection < Valkyrie::Resource
        attribute :collection_has_child_collection_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
        attribute :collection_has_child_work_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
      end
      class Work < Valkyrie::Resource
        attribute :work_has_child_work_ids, Valkyrie::Types::Set
        attribute :work_has_child_file_set_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
      end
      class FileSet < Valkyrie::Resource; end
    end
  end

  after { Hyrax::Test.send(:remove_const, :FindRelated) }

  let(:collection_id1) { Valkyrie::ID.new'col1' }
  let(:collection_id2) { Valkyrie::ID.new'col2' }
  let(:collection_id3) { Valkyrie::ID.new'col3' }
  let!(:collection1) do
    persister.save(resource:
      Hyrax::Test::FindRelated::Collection.new.tap do |c|
        c.id = collection_id1
        c.collection_has_child_collection_ids = [collection_id2, collection_id3]
        c.collection_has_child_work_ids = [work_id1]
      end)
  end
  let!(:collection2) do
    persister.save(resource:
      Hyrax::Test::FindRelated::Collection.new.tap do |c|
        c.id = collection_id2
        c.collection_has_child_work_ids = [work_id1, work_id2]
      end)
  end
  let!(:collection3) { persister.save(resource: Hyrax::Test::FindRelated::Collection.new(id: collection_id3)) }

  let(:work_id1) { Valkyrie::ID.new'wk1' }
  let(:work_id2) { Valkyrie::ID.new'wk2' }
  let(:work_id3) { Valkyrie::ID.new'wk3' }
  let!(:work1) do
    persister.save(resource:
      Hyrax::Test::FindRelated::Work.new.tap do |w|
        w.id = work_id1
        w.work_has_child_work_ids = [work_id3, 'NOT_AN_ID']
        w.work_has_child_file_set_ids = [fileset_id1, fileset_id2]
      end)
  end
  let!(:work2) do
    persister.save(resource:
      Hyrax::Test::FindRelated::Work.new.tap do |w|
        w.id = work_id2
        w.work_has_child_work_ids = [work_id3]
      end)
  end
  let!(:work3) { persister.save(resource: Hyrax::Test::FindRelated::Work.new(id: work_id3)) }

  let(:fileset_id1) { Valkyrie::ID.new'fs1' }
  let(:fileset_id2) { Valkyrie::ID.new'fs2' }
  let!(:fileset1) { persister.save(resource: Hyrax::Test::FindRelated::FileSet.new(id: fileset_id1)) }
  let!(:fileset2) { persister.save(resource: Hyrax::Test::FindRelated::FileSet.new(id: fileset_id2)) }

  describe '.find_related_ids_for' do
    context 'when all values for the relationship are ids' do
      subject { query_service.custom_queries.find_related_ids_for(resource: work1, relationship: :work_has_child_file_set_ids) }
      it 'returns all related' do
        expect(subject).to contain_exactly(fileset_id1, fileset_id2)
      end
    end

    context 'when mix of ids and other types for the relationship' do
      subject { query_service.custom_queries.find_related_ids_for(resource: work1, relationship: :work_has_child_work_ids) }
      it 'returns only related values that are ids' do
        expect(subject).to contain_exactly(work_id3)
      end
    end

    context 'when there are no resources with the relationship' do
      subject { query_service.custom_queries.find_related_ids_for(resource: collection2, relationship: :collection_has_child_collection_ids) }
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end

    context "when the relationship isn't defined on the resource" do
      subject { query_service.custom_queries.find_related_ids_for(resource: collection1, relationship: :work_has_child_file_set_ids) }
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end
  end

  describe '.find_related_for' do
    context 'when all values for the relationship are ids' do
      subject { query_service.custom_queries.find_related_for(resource: work1, relationship: :work_has_child_file_set_ids) }
      it 'returns all related' do
        expect(subject.map(&:class).first).to eq(Hyrax::Test::FindRelated::FileSet)
        expect(subject.map(&:id)).to contain_exactly(fileset_id1, fileset_id2)
      end
    end

    context 'when mix of ids and other types for the relationship' do
      subject { query_service.custom_queries.find_related_for(resource: work1, relationship: :work_has_child_work_ids) }
      it 'returns only related values that are ids' do
        expect(subject.map(&:class).first).to eq(Hyrax::Test::FindRelated::Work)
        expect(subject.map(&:id)).to contain_exactly(work_id3)
      end
    end

    context 'when there are no resources with the relationship' do
      subject { query_service.custom_queries.find_related_ids_for(resource: collection2, relationship: :collection_has_child_collection_ids) }
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end

    context "when the relationship isn't defined on the resource" do
      subject { query_service.custom_queries.find_related_ids_for(resource: collection1, relationship: :work_has_child_file_set_ids) }
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end
  end

  describe '.find_inverse_related_ids_for' do
    context 'when there are inverse related resources' do
      subject { query_service.custom_queries.find_inverse_related_ids_for(resource: fileset1, relationship: :work_has_child_file_set_ids) }
      it 'returns all inverse related' do
        expect(subject).to contain_exactly(work_id1)
      end
    end

    context "when there aren't any inverse related resources" do
      subject { query_service.custom_queries.find_inverse_related_ids_for(resource: collection1, relationship: :collection_has_child_collection_ids) }
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end
  end

  describe '.find_inverse_related_for' do
    context 'when there are inverse related resources' do
      subject { query_service.custom_queries.find_inverse_related_for(resource: work3, relationship: :work_has_child_work_ids) }
      it 'returns all related' do
        expect(subject.map(&:class).first).to eq(Hyrax::Test::FindRelated::Work)
        expect(subject.map(&:id)).to contain_exactly(work_id1, work_id2)
      end
    end

    context "when there aren't any inverse related resources" do
      subject { query_service.custom_queries.find_inverse_related_for(resource: collection1, relationship: :collection_has_child_collection_ids) }
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end
  end
end
