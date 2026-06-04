# frozen_string_literal: true

RSpec.describe Hyrax::CompoundSchema do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestResourceWithCompounds'
      end

      attribute :title, Valkyrie::Types::Array.of(Valkyrie::Types::String)
      attribute :contributors,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subfields: {
                    'given_name' => { 'type' => 'string', 'index_keys' => %w[contributors_given_name_sim contributors_given_name_tesim] },
                    'family_name' => { 'type' => 'string', 'index_keys' => %w[contributors_family_name_tesim] },
                    'role_label' => { 'type' => 'controlled', 'authority' => 'contributor_role', 'display' => false }
                  },
                  groups: [
                    { 'label' => 'Identity', 'cols' => 6, 'fields' => %w[given_name family_name] },
                    { 'label' => 'Role', 'cols' => 6, 'fields' => %w[role_label] }
                  ]
                )
      attribute :identifiers,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subfields: {
                    'value' => { 'type' => 'string' },
                    'identifier_type' => { 'type' => 'controlled', 'authority' => 'identifier_type' }
                  }
                )
      attribute :agent,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subfields: {
                    'agent_name' => { 'type' => 'string' },
                    'agent_role' => { 'type' => 'controlled', 'values' => ['Author', { 'id' => 'ed', 'label' => 'Editor' }] }
                  }
                )
      attribute :relationships,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subfields: {
                    'related_item' => { 'type' => 'work_or_url' },
                    'relationship_type' => { 'type' => 'controlled', 'authority' => 'relationship_type' }
                  },
                  view: { 'display' => 'card' }
                )
      # Required at the compound level (non-flexible `required: true`) with two
      # required sub-fields and one optional.
      attribute :required_compound,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  required: true,
                  subfields: {
                    'item' => { 'type' => 'string', 'required' => true },
                    'kind' => { 'type' => 'string', 'required' => true },
                    'note' => { 'type' => 'string' }
                  }
                )
      # Required at the compound level via m3 minimum cardinality (flexible).
      attribute :cardinality_compound,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  cardinality: { 'minimum' => 1 },
                  subfields: { 'value' => { 'type' => 'string' } }
                )
    end
  end

  subject(:schema) { described_class.for(resource_class) }

  describe '#compound_names' do
    it 'returns only the attributes that declare subfields' do
      expect(schema.compound_names).to contain_exactly(:contributors, :identifiers, :agent, :relationships,
                                                       :required_compound, :cardinality_compound)
    end

    it 'does not treat a plain scalar attribute as a compound' do
      expect(schema.compound_names).not_to include(:title)
    end
  end

  describe 'display mode (view: { display: card })' do
    describe '#inline_compound_names' do
      it 'excludes compounds declared as cards' do
        expect(schema.inline_compound_names).to contain_exactly(:contributors, :identifiers, :agent,
                                                                :required_compound, :cardinality_compound)
      end
    end

    describe '#card_compound_names' do
      it 'returns only compounds declared as cards' do
        expect(schema.card_compound_names).to contain_exactly(:relationships)
      end
    end

    describe '#card?' do
      it 'is true for a compound declared view: { display: card }' do
        expect(schema.card?(:relationships)).to be true
        expect(schema.card?('relationships')).to be true
      end

      it 'is false for an inline (default) compound' do
        expect(schema.card?(:contributors)).to be false
      end

      it 'is false for a non-compound attribute' do
        expect(schema.card?(:title)).to be false
      end
    end

    it 'records the display_mode on the definition' do
      expect(schema.definition_for(:relationships)[:display_mode]).to eq(:card)
      expect(schema.definition_for(:contributors)[:display_mode]).to eq(:inline)
    end
  end

  describe 'required declarations' do
    describe '#required?' do
      it 'is true when the compound declares required: true' do
        expect(schema.required?(:required_compound)).to be true
      end

      it 'is true when a minimum cardinality of 1 is declared (m3/flexible)' do
        expect(schema.required?(:cardinality_compound)).to be true
      end

      it 'is false for an optional compound' do
        expect(schema.required?(:relationships)).to be false
      end

      it 'is false for a non-compound attribute' do
        expect(schema.required?(:title)).to be false
      end
    end

    describe '#required_subfield_keys' do
      it 'returns the sub-fields declared required: true' do
        expect(schema.required_subfield_keys(:required_compound)).to eq(%w[item kind])
      end

      it 'is empty when no sub-field is required' do
        expect(schema.required_subfield_keys(:relationships)).to eq([])
      end

      it 'is empty for a non-compound' do
        expect(schema.required_subfield_keys(:title)).to eq([])
      end
    end

    it 'records required on the definition (subfield + compound level)' do
      definition = schema.definition_for(:required_compound)
      expect(definition[:required]).to be true
      expect(definition[:subfields]['item'][:required]).to be true
      expect(definition[:subfields]['note'][:required]).to be false
    end
  end

  describe '#compound?' do
    it 'is true for a declared compound' do
      expect(schema.compound?(:contributors)).to be true
      expect(schema.compound?('contributors')).to be true
    end

    it 'is false for a non-compound attribute' do
      expect(schema.compound?(:title)).to be false
    end
  end

  describe '#subfield_keys' do
    it 'returns the ordered sub-field keys' do
      expect(schema.subfield_keys(:contributors)).to eq(%w[given_name family_name role_label])
    end

    it 'is empty for a non-compound' do
      expect(schema.subfield_keys(:title)).to eq([])
    end
  end

  describe '#definition_for' do
    it 'normalizes subfields with type, authority, index_keys and display' do
      definition = schema.definition_for(:contributors)
      expect(definition[:subfields]['role_label'])
        .to eq(type: 'controlled', authority: 'contributor_role', values: nil, index_keys: [], display: false, required: false)
      expect(definition[:subfields]['given_name'])
        .to eq(type: 'string', authority: nil, values: nil,
               index_keys: %w[contributors_given_name_sim contributors_given_name_tesim], display: true, required: false)
    end

    it 'reads per-sub-field index_keys (literal Solr field names)' do
      expect(schema.definition_for(:contributors)[:subfields]['family_name'][:index_keys])
        .to eq(%w[contributors_family_name_tesim])
    end

    it 'defaults a sub-field with no index declaration to no index_keys' do
      expect(schema.definition_for(:agent)[:subfields]['agent_name'][:index_keys]).to eq([])
    end

    it 'defaults display to true and honors display: false' do
      expect(schema.definition_for(:contributors)[:subfields]['given_name'][:display]).to be true
      expect(schema.definition_for(:contributors)[:subfields]['role_label'][:display]).to be false
    end

    it 'normalizes an inline controlled-vocabulary values list to [label, id] pairs' do
      values = schema.definition_for(:agent)[:subfields]['agent_role'][:values]
      expect(values).to eq([%w[Author Author], %w[Editor ed]])
    end

    it 'carries the declared groups' do
      groups = schema.definition_for(:contributors)[:groups]
      expect(groups).to eq([
                             { label: 'Identity', cols: 6, fields: %w[given_name family_name] },
                             { label: 'Role', cols: 6, fields: %w[role_label] }
                           ])
    end

    it 'defaults groups to a single all-fields group when none declared' do
      groups = schema.definition_for(:identifiers)[:groups]
      expect(groups).to eq([{ label: nil, cols: 6, fields: %w[value identifier_type] }])
    end
  end

  describe '.for' do
    it 'builds from a resource instance' do
      expect(described_class.for(resource_class.new).compound_names)
        .to contain_exactly(:contributors, :identifiers, :agent, :relationships,
                            :required_compound, :cardinality_compound)
    end
  end

  describe '.for_solr_document' do
    # The attribute map a flexible schema loader returns for a version:
    # `{ name => dry_type_with_meta }` — the same shape SchemaLoader#attributes_for
    # produces. Show pages resolve compounds from this (via schema_version)
    # without loading the resource.
    let(:version_attributes) do
      resource_class.schema.index_by(&:name)
    end

    context 'in flexible mode (document has a schema_version)' do
      let(:document) { instance_double(SolrDocument, hydra_model: resource_class) }

      before do
        allow(document).to receive(:[]).with('schema_version_ssi').and_return('7')
        loader = instance_double(Hyrax::M3SchemaLoader)
        allow(Hyrax::Schema).to receive(:m3_schema_loader).and_return(loader)
        allow(loader).to receive(:attributes_for)
          .with(schema: 'TestResourceWithCompounds', version: '7', contexts: [])
          .and_return(version_attributes)
      end

      it 'resolves compounds from the version attribute map (no resource load)' do
        expect(described_class.for_solr_document(document).card_compound_names)
          .to contain_exactly(:relationships)
      end
    end

    context 'when the document has no schema_version (non-flexible)' do
      let(:document) { instance_double(SolrDocument, hydra_model: resource_class) }

      before { allow(document).to receive(:[]).with('schema_version_ssi').and_return(nil) }

      it 'falls back to the model class schema' do
        expect(described_class.for_solr_document(document).compound_names)
          .to include(:relationships, :agent)
      end
    end
  end
end
