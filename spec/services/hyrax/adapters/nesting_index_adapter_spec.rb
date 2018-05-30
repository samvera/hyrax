require 'samvera/nesting_indexer/adapters/interface_behavior_spec'

RSpec.describe Hyrax::Adapters::NestingIndexAdapter do
  it_behaves_like 'a Samvera::NestingIndexer::Adapter'

  describe '.find_preservation_document_by' do
    let(:id) { '123' }

    subject { described_class.find_preservation_document_by(id: id) }

    context 'with a not found fedora document ' do
      let(:id) { 'so-very-missing-no-document-here' }

      it 'raises ActiveFedora::ObjectNotFound' do
        expect { subject }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
    context 'with fedora document that does not have #member_of_collection_ids' do
      let(:document) { double("Document", id: id) }

      before do
        expect(ActiveFedora::Base).to receive(:find).with(document.id).and_return(document)
      end

      it { is_expected.to be_a(Samvera::NestingIndexer::Documents::PreservationDocument) }
    end
    context 'with fedora document that has #member_of_collection_ids' do
      let(:document) { double("Document", id: id, member_of_collection_ids: ['456', '789']) }

      before do
        expect(ActiveFedora::Base).to receive(:find).with(document.id).and_return(document)
      end

      it { is_expected.to be_a(Samvera::NestingIndexer::Documents::PreservationDocument) }
    end
  end

  describe '.find_index_document_by' do
    subject { described_class.find_index_document_by(id: id) }

    context 'with id not in solr, it builds from Fedora' do
      let(:id) { 'so-very-missing-no-document-here' }
      let(:document) { double("Document", id: id, fetch: nil) }
      let(:object) { double("Object_to_reindex", id: id, to_solr: document) }

      before do
        allow(ActiveFedora::Base).to receive(:find).with(id).and_return(object)
      end

      it { is_expected.to be_a(Samvera::NestingIndexer::Documents::IndexDocument) }
    end

    context 'with a found id' do
      let(:id) { "abc-def-ghi" }
      let(:document) { { id: id } }

      before do
        ActiveFedora::SolrService.delete(id)
        ActiveFedora::SolrService.add(document, commit: true)
      end

      it { is_expected.to be_a(Samvera::NestingIndexer::Documents::IndexDocument) }
    end
  end

  describe '.each_perservation_document_id_and_parent_ids', clean_repo: true do
    let!(:nested_parent) { create(:collection, member_of_collections: []) }
    let!(:nested_with_parent) { create(:collection, member_of_collections: [nested_parent]) }
    let!(:work) { create(:generic_work) }
    let(:count_of_items) { ActiveFedora::Base.descendant_uris(ActiveFedora.fedora.base_uri, exclude_uri: true).count }

    it 'uses direct add to Solr on non-nested objects but yields the document and parent_ids to allow nesting logic to fire' do
      # The two collections and the work are handled via the nesting indexer.
      # we expect remaining repository objects to reindex via to_solr.
      expect(ActiveFedora::SolrService).to receive(:add).exactly(count_of_items - 3).times
      yielded = []
      described_class.each_perservation_document_id_and_parent_ids do |document_id, parent_ids|
        yielded << [document_id, parent_ids]
      end
      # collections or works with parents do not yield, so parent_ids should always be an empty array, and nested_with_parent is not yielded.
      expect(yielded).to contain_exactly([work.id, []], [nested_parent.id, []])
    end
  end

  describe '.each_child_document_of', clean_repo: true do
    let(:ancestors_key) { described_class.solr_field_name_for_storing_ancestors }
    let(:pathnames_key) { described_class.solr_field_name_for_storing_pathnames }
    let(:index_document_class) { Samvera::NestingIndexer::Documents::IndexDocument }
    let(:parent) { { id: document.id } }
    let(:document) { index_document_class.new(id: 'parent-1', pathnames: ['parent-1'], parent_ids: [], ancestors: []) }
    let(:children) do
      [{ id: 'child-1',
         member_of_collection_ids_ssim: [document.id],
         ancestors_key => [document.id],
         pathnames_key => ['child-1'] },
       { id: 'child-2',
         member_of_collection_ids_ssim: [document.id],
         ancestors_key => [document.id] }]
    end
    let(:not_my_children) do
      [{ id: 'youre-not-my-dad-1',
         member_of_collection_ids_ssim: ['parent-2'],
         ancestors_key => ['parent-2'],
         pathnames_key => ['youre-not-my-dad-1'] },
       { id: 'i-am-your-grandchild',
         member_of_collection_ids_ssim: ['parent-3'],
         ancestors_key => ['parent-1/parent-3'],
         pathnames_key => ['i-am-your-grandchild'] }]
    end

    before do
      ([parent] + children + not_my_children).each do |doc|
        ActiveFedora::SolrService.add(doc, commit: true)
      end
    end

    context 'with full reindexing extent' do
      it 'yields all of the child solr-documents of the given document' do
        child_index_documents = []
        described_class.each_child_document_of(document: document, extent: Hyrax::Adapters::NestingIndexAdapter::FULL_REINDEX) do |doc|
          child_index_documents << doc
        end
        expect(child_index_documents.count).to eq(2)
        child_index_documents.each do |child|
          expect(child).to be_a(index_document_class)
          expect(child.ancestors).to eq([document.id])
        end
      end
    end

    context 'with limited reindexing extent' do
      it 'yields only child documents without pathnames' do
        child_index_documents = []
        described_class.each_child_document_of(document: document, extent: Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX) do |doc|
          child_index_documents << doc
        end
        expect(child_index_documents.count).to eq(1)
        child_index_documents.each do |child|
          expect(child).to be_a(index_document_class)
          expect(child.ancestors).to eq([document.id])
        end
      end
    end
  end

  describe '.write_nesting_document_to_index_layer' do
    let(:work) { create(:work) }
    let(:query_for_works_solr_document) { ->(id:) { ActiveFedora::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id])).first } }

    # rubocop:disable RSpec/ExampleLength
    it 'will append parent_ids, ancestors, pathnames, and deepest_nested_depth to the SOLR document' do
      previous_solr_keys = work.to_solr.keys
      expect(previous_solr_keys).not_to include(described_class.solr_field_name_for_storing_ancestors)
      expect(previous_solr_keys).not_to include(described_class.solr_field_name_for_storing_parent_ids)
      expect(previous_solr_keys).not_to include(described_class.solr_field_name_for_storing_pathnames)
      expect(previous_solr_keys).not_to include(described_class.solr_field_name_for_deepest_nested_depth)

      existing_queried_solr_document = query_for_works_solr_document.call(id: work.id)
      expect(existing_queried_solr_document).not_to be_key(described_class.solr_field_name_for_storing_ancestors)
      expect(existing_queried_solr_document).not_to be_key(described_class.solr_field_name_for_storing_parent_ids)
      expect(existing_queried_solr_document).not_to be_key(described_class.solr_field_name_for_storing_pathnames)
      expect(existing_queried_solr_document).not_to be_key(described_class.solr_field_name_for_deepest_nested_depth)

      nesting_document = Samvera::NestingIndexer::Documents::IndexDocument.new(
        id: work.id,
        parent_ids: ['123'],
        pathnames: ["123#{Samvera::NestingIndexer::Documents::ANCESTOR_AND_PATHNAME_DELIMITER}#{work.id}"],
        ancestors: ['123']
      )
      returned_solr_document = described_class.write_nesting_document_to_index_layer(nesting_document: nesting_document)

      expect(returned_solr_document.fetch(described_class.solr_field_name_for_storing_ancestors)).to eq(nesting_document.ancestors)
      expect(returned_solr_document.fetch(described_class.solr_field_name_for_storing_parent_ids)).to eq(nesting_document.parent_ids)
      expect(returned_solr_document.fetch(described_class.solr_field_name_for_storing_pathnames)).to eq(nesting_document.pathnames)
      expect(returned_solr_document.fetch(described_class.solr_field_name_for_deepest_nested_depth)).to eq(nesting_document.deepest_nested_depth)

      newly_queried_solr_document = query_for_works_solr_document.call(id: work.id)
      expect(newly_queried_solr_document.fetch(described_class.solr_field_name_for_storing_ancestors)).to eq(nesting_document.ancestors)
      expect(newly_queried_solr_document.fetch(described_class.solr_field_name_for_storing_parent_ids)).to eq(nesting_document.parent_ids)
      expect(newly_queried_solr_document.fetch(described_class.solr_field_name_for_storing_pathnames)).to eq(nesting_document.pathnames)
      expect(newly_queried_solr_document.fetch(described_class.solr_field_name_for_deepest_nested_depth)).to eq(nesting_document.deepest_nested_depth)
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe '.solr_field_name_for_storing_ancestors' do
    subject { described_class.solr_field_name_for_storing_ancestors }

    it { is_expected.to match(/_ssim$/) }
  end

  describe '.solr_field_name_for_deepest_nested_depth' do
    subject { described_class.solr_field_name_for_deepest_nested_depth }

    it 'is expected to be a single value integer' do
      expect(subject).to match(/_isi$/)
    end
  end

  describe '.solr_field_name_for_storing_parent_ids' do
    subject { described_class.solr_field_name_for_storing_parent_ids }

    it { is_expected.to match(/_ssim$/) }
  end
end
