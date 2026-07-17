# frozen_string_literal: true

RSpec.describe Hyrax::Indexers::CompoundIndexer do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestIndexedCompoundResource'
      end

      # Raw subproperty declarations (the shape a profile carries); CompoundSchema
      # normalizes them before the indexer sees them. Demonstrates the four
      # indexing states: explicit list, derived (default), opt-out, display:false.
      attribute :contributors,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    # explicit index_keys override: written verbatim
                    'given_name' => { 'type' => 'string',
                                      'index_keys' => %w[contributors_given_name_tesim contributors_given_name_sim] },
                    # derived (no index_keys): string -> _sim + _tesim, prefixed by compound
                    'family_name' => { 'type' => 'string' },
                    # derived from a controlled type: facet-only (_sim)
                    'role_label' => { 'type' => 'controlled' },
                    # opted out (indexing: false): no Solr field, but still in the display blob
                    'affiliation' => { 'type' => 'string', 'indexing' => false },
                    # derived but excluded from the display blob (display: false)
                    'note' => { 'type' => 'string', 'display' => false }
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
                           { 'given_name' => 'Ada', 'family_name' => 'Lovelace', 'role_label' => 'author',
                             'affiliation' => 'Analytical Society', 'note' => 'n1' },
                           { 'given_name' => 'Alan', 'family_name' => 'Turing', 'role_label' => 'author',
                             'affiliation' => "King's College", 'note' => 'n2' }
                         ])
    end

    it 'writes an explicit index_keys list verbatim' do
      doc = indexer.to_solr
      expect(doc['contributors_given_name_tesim']).to contain_exactly('Ada', 'Alan')
      expect(doc['contributors_given_name_sim']).to contain_exactly('Ada', 'Alan')
    end

    it 'derives <compound>_<name>_<suffix> for a sub-property with no explicit index_keys' do
      doc = indexer.to_solr
      # string -> _sim + _tesim, prefixed by the compound name
      expect(doc['contributors_family_name_sim']).to contain_exactly('Lovelace', 'Turing')
      expect(doc['contributors_family_name_tesim']).to contain_exactly('Lovelace', 'Turing')
      # controlled derives facet-only (_sim), no _tesim
      expect(doc['contributors_role_label_sim']).to contain_exactly('author', 'author')
      expect(doc.keys).not_to include('contributors_role_label_tesim')
    end

    it 'writes no Solr field for a sub-property that opts out of indexing (index: false)' do
      expect(indexer.to_solr.keys.grep(/affiliation/)).to be_empty
    end

    context 'when a controlled member value is itself an array' do
      let(:resource) do
        resource_class.new(contributors: [
                             { 'given_name' => 'Ada', 'role_label' => %w[author editor] },
                             { 'given_name' => 'Alan', 'role_label' => 'author' }
                           ])
      end

      it 'flattens each term into its own facet value rather than nesting the array' do
        expect(indexer.to_solr['contributors_role_label_sim']).to contain_exactly('author', 'editor', 'author')
      end
    end

    it 'accepts symbol-keyed entries (JSONValueMapper reload shape)' do
      resource.contributors = [{ given_name: 'Grace', family_name: 'Hopper' }]
      doc = indexer.to_solr
      expect(doc['contributors_given_name_tesim']).to contain_exactly('Grace')
      expect(doc['contributors_family_name_sim']).to contain_exactly('Hopper')
    end

    it 'stores the displayable sub-properties as a JSON blob for the show page' do
      parsed = JSON.parse(indexer.to_solr['contributors_json_ss'])
      # affiliation (opted out of indexing) is still displayed; note (display: false) is omitted.
      expect(parsed).to eq([
                             { 'given_name' => 'Ada', 'family_name' => 'Lovelace', 'role_label' => 'author',
                               'affiliation' => 'Analytical Society' },
                             { 'given_name' => 'Alan', 'family_name' => 'Turing', 'role_label' => 'author',
                               'affiliation' => "King's College" }
                           ])
    end

    it 'omits display: false sub-properties from the blob even though they are indexed' do
      parsed = JSON.parse(indexer.to_solr['contributors_json_ss'])
      expect(parsed.first).not_to have_key('note')
      # ...but `note` is still written to its own derived searchable field
      expect(indexer.to_solr['contributors_note_tesim']).to contain_exactly('n1', 'n2')
    end
  end

  context 'for a resource with no compound entries' do
    let(:resource) { resource_class.new(contributors: []) }

    it 'emits no compound Solr fields' do
      expect(indexer.to_solr.keys).not_to include('contributors_given_name_tesim', 'contributors_json_ss')
    end
  end

  context 'with one sub-property reused across two compounds (derived per-parent)' do
    # The same `title` sub-property folded into two compounds derives distinct,
    # collision-free Solr fields — the reason derivation replaces hand-written
    # prefixes.
    let(:reuse_class) do
      title_spec = { 'type' => 'string' }
      Class.new(Hyrax::Resource) do
        def self.name
          'TestReusedSubpropertyResource'
        end
        attribute :participants,
                  Valkyrie::Types::Array.of(Dry::Types['hash']).meta(subproperties: { 'title' => title_spec })
        attribute :relationships,
                  Valkyrie::Types::Array.of(Dry::Types['hash']).meta(subproperties: { 'title' => title_spec })
      end
    end
    let(:resource) do
      reuse_class.new(participants: [{ 'title' => 'Chair' }],
                      relationships: [{ 'title' => 'Sequel' }])
    end
    let(:indexer) { host_indexer_class.new(resource: resource) }

    it 'writes a distinct field per parent compound' do
      doc = indexer.to_solr
      expect(doc['participants_title_tesim']).to contain_exactly('Chair')
      expect(doc['relationships_title_tesim']).to contain_exactly('Sequel')
    end
  end

  context 'with a datepicker sub-property' do
    # A datepicker stores an ISO YYYY-MM-DD string and indexes like a string
    # (facetable _sim plus full-text _tesim), never as a _dtsi date field, which
    # would reject the date-only value.
    let(:date_class) do
      Class.new(Hyrax::Resource) do
        def self.name
          'TestDatepickerCompoundResource'
        end
        attribute :dates,
                  Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                    subproperties: { 'start_date' => { 'type' => 'datepicker' } }
                  )
      end
    end
    let(:resource) { date_class.new(dates: [{ 'start_date' => '2025-03-01' }]) }
    let(:indexer) { host_indexer_class.new(resource: resource) }

    it 'derives _sim and _tesim for a datepicker, not a _dtsi date field' do
      doc = indexer.to_solr
      expect(doc['dates_start_date_sim']).to contain_exactly('2025-03-01')
      expect(doc['dates_start_date_tesim']).to contain_exactly('2025-03-01')
      expect(doc.keys).not_to include('dates_start_date_dtsi')
    end
  end
end
