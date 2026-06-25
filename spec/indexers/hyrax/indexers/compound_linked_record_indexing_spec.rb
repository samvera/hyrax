# frozen_string_literal: true

# A `linked_record` sub-property references a row in a database table. It indexes
# like an id/reference: a single stored-string field `<compound>_<name>_ssim`,
# for reverse lookup ("which works name this record?"). This mirrors how
# `work_or_url` derives `_ssim`; without the suffix mapping an unknown type
# falls back to the default `_tesim`.
RSpec.describe 'linked_record compound indexing' do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestLinkedRecordIndexingResource'
      end

      attribute :people,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    # the linked-record reference (a row id/key)
                    'person' => { 'type' => 'linked_record' },
                    # a plain string sub-field alongside it, to confirm normal
                    # derivation is untouched
                    'role' => { 'type' => 'string' }
                  }
                )
    end
  end

  let(:host_indexer_class) do
    Class.new(Hyrax::Indexers::ResourceIndexer) do
      include Hyrax::Indexers::CompoundIndexer
    end
  end

  let(:indexer) { host_indexer_class.new(resource:) }
  let(:resource) do
    resource_class.new(people: [
                         { 'person' => 'p-123', 'role' => 'Author' },
                         { 'person' => 'p-456', 'role' => 'Editor' }
                       ])
  end

  it 'derives a single stored-string field <compound>_<name>_ssim for the linked_record' do
    doc = indexer.to_solr
    expect(doc['people_person_ssim']).to contain_exactly('p-123', 'p-456')
  end

  it 'does not derive text/facet fields for the linked_record reference' do
    doc = indexer.to_solr
    expect(doc.keys).not_to include('people_person_tesim')
    expect(doc.keys).not_to include('people_person_sim')
  end

  it 'leaves sibling string sub-properties deriving normally (_sim + _tesim)' do
    doc = indexer.to_solr
    expect(doc['people_role_sim']).to contain_exactly('Author', 'Editor')
    expect(doc['people_role_tesim']).to contain_exactly('Author', 'Editor')
  end
end
