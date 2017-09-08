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

    context 'with a not found id ' do
      let(:id) { 'so-very-missing-no-document-here' }

      it 'raises RuntimeError' do
        expect { subject }.to raise_error(RuntimeError)
      end
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

  describe '.each_preservation_document' do
    xit 'iterates through each preservation document'
  end

  describe '.each_child_document_of', clean_repo: true do
    let(:ancestors_key) { described_class.solr_field_name_for_storing_ancestors }
    let(:index_document_class) { Samvera::NestingIndexer::Documents::IndexDocument }
    let(:parent) { { id: document.id } }
    let(:document) { index_document_class.new(id: 'parent-1', pathnames: ['parent-1'], parent_ids: [], ancestors: []) }
    let(:children) { [{ id: 'child-1', ancestors_key => [document.id] }, { id: 'child-2', ancestors_key => [document.id] }] }
    let(:not_my_children) { [{ id: 'youre-not-my-dad-1', ancestors_key => ['parent-2'] }, { id: 'i-am-your-grandchild', ancestors_key => ['parent-1/parent-3'] }] }

    before do
      ([parent] + children + not_my_children).each do |doc|
        ActiveFedora::SolrService.add(doc, commit: true)
      end
    end

    it 'yields all of the child solr-documents of the given document' do
      child_index_documents = []
      described_class.each_child_document_of(document: document) do |doc|
        child_index_documents << doc
      end
      expect(child_index_documents.count).to eq(2)
      child_index_documents.each do |child|
        expect(child).to be_a(index_document_class)
        expect(child.ancestors).to eq([document.id])
      end
    end
  end

  describe '.write_document_attributes_to_index_layer' do
    let(:work) { create(:work) }
    let(:query_for_works_solr_document) { ->(id:) { ActiveFedora::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id])).first } }

    # rubocop:disable RSpec/ExampleLength
    it 'will append parent_ids, ancestors, and pathnames' do
      previous_solr_keys = work.to_solr.keys
      expect(previous_solr_keys).not_to include(described_class.solr_field_name_for_storing_ancestors)
      expect(previous_solr_keys).not_to include(described_class.solr_field_name_for_storing_parent_ids)
      expect(previous_solr_keys).not_to include(described_class.solr_field_name_for_storing_pathnames)

      existing_queried_solr_document = query_for_works_solr_document.call(id: work.id)
      expect(existing_queried_solr_document.key?(described_class.solr_field_name_for_storing_ancestors)).to be_falsey
      expect(existing_queried_solr_document.key?(described_class.solr_field_name_for_storing_parent_ids)).to be_falsey
      expect(existing_queried_solr_document.key?(described_class.solr_field_name_for_storing_pathnames)).to be_falsey

      kwargs = { id: work.id, parent_ids: ['123'], pathnames: ["123/#{work.id}"], ancestors: ['123'] }
      returned_solr_document = described_class.write_document_attributes_to_index_layer(**kwargs)

      expect(returned_solr_document.fetch(described_class.solr_field_name_for_storing_ancestors)).to eq(kwargs.fetch(:ancestors))
      expect(returned_solr_document.fetch(described_class.solr_field_name_for_storing_parent_ids)).to eq(kwargs.fetch(:parent_ids))
      expect(returned_solr_document.fetch(described_class.solr_field_name_for_storing_pathnames)).to eq(kwargs.fetch(:pathnames))

      newly_queried_solr_document = query_for_works_solr_document.call(id: work.id)
      expect(newly_queried_solr_document.fetch(described_class.solr_field_name_for_storing_ancestors)).to eq(kwargs.fetch(:ancestors))
      expect(newly_queried_solr_document.fetch(described_class.solr_field_name_for_storing_parent_ids)).to eq(kwargs.fetch(:parent_ids))
      expect(newly_queried_solr_document.fetch(described_class.solr_field_name_for_storing_pathnames)).to eq(kwargs.fetch(:pathnames))
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe '.solr_field_name_for_storing_ancestors' do
    subject { described_class.solr_field_name_for_storing_ancestors }

    it { is_expected.to match(/_ssim$/) }
  end

  describe '.solr_field_name_for_storing_parent_ids' do
    subject { described_class.solr_field_name_for_storing_parent_ids }

    it { is_expected.to match(/_ssim$/) }
  end
end
