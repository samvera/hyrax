# frozen_string_literal: true

RSpec.describe Hyrax::Indexers::CompoundIndexer do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestIndexedCompoundResource'
      end

      attribute :contributors,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subfields: {
                    # searchable + facetable, via the literal field names the
                    # sub-field declares
                    'given_name' => { 'type' => 'string',
                                      'index_keys' => %w[contributors_given_name_tesim contributors_given_name_sim] },
                    # searchable only
                    'family_name' => { 'type' => 'string',
                                       'index_keys' => %w[contributors_family_name_tesim] },
                    # display-only: no index_keys, so no own Solr field, but in the blob
                    'role_label' => { 'type' => 'controlled', 'authority' => 'contributor_role' },
                    # searchable but excluded from the display blob
                    'note' => { 'type' => 'string', 'index_keys' => %w[contributors_note_tesim], 'display' => false }
                  }
                )
    end
  end

  let(:host_indexer_class) do
    Class.new(Hyrax::Indexers::ResourceIndexer) do
      include Hyrax::Indexers::CompoundIndexer
    end
  end

  let(:indexer) { host_indexer_class.new(resource: resource) }

  context 'for a resource with compound entries' do
    let(:resource) do
      resource_class.new(contributors: [
                           { 'given_name' => 'Ada', 'family_name' => 'Lovelace', 'role_label' => 'author', 'note' => 'n1' },
                           { 'given_name' => 'Alan', 'family_name' => 'Turing', 'role_label' => 'author', 'note' => 'n2' }
                         ])
    end

    it 'writes each sub-field value to the literal Solr field names it declares' do
      doc = indexer.to_solr
      expect(doc['contributors_given_name_tesim']).to contain_exactly('Ada', 'Alan')
      expect(doc['contributors_given_name_sim']).to contain_exactly('Ada', 'Alan')
      expect(doc['contributors_family_name_tesim']).to contain_exactly('Lovelace', 'Turing')
    end

    it 'does not write a Solr field for a sub-field with no index_keys' do
      # role_label declares no index_keys; it has no field of its own.
      expect(indexer.to_solr.keys.grep(/role_label/)).to be_empty
    end

    it 'accepts symbol-keyed entries (JSONValueMapper reload shape)' do
      resource.contributors = [{ given_name: 'Grace', family_name: 'Hopper' }]
      doc = indexer.to_solr
      expect(doc['contributors_given_name_tesim']).to contain_exactly('Grace')
    end

    it 'stores the displayable sub-fields as a JSON blob for the show page' do
      parsed = JSON.parse(indexer.to_solr['contributors_json_ss'])
      # role_label (display-only) is included; note (display: false) is omitted.
      expect(parsed).to eq([
                             { 'given_name' => 'Ada', 'family_name' => 'Lovelace', 'role_label' => 'author' },
                             { 'given_name' => 'Alan', 'family_name' => 'Turing', 'role_label' => 'author' }
                           ])
    end

    it 'omits display: false sub-fields from the blob even though they are indexed' do
      parsed = JSON.parse(indexer.to_solr['contributors_json_ss'])
      expect(parsed.first).not_to have_key('note')
      # ...but `note` is still written to its own searchable field
      expect(indexer.to_solr['contributors_note_tesim']).to contain_exactly('n1', 'n2')
    end
  end

  context 'for a resource with no compound entries' do
    let(:resource) { resource_class.new(contributors: []) }

    it 'emits no compound Solr fields' do
      expect(indexer.to_solr.keys).not_to include('contributors_given_name_tesim', 'contributors_json_ss')
    end
  end
end
