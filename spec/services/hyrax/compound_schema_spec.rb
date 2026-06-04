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
    end
  end

  subject(:schema) { described_class.for(resource_class) }

  describe '#compound_names' do
    it 'returns only the attributes that declare subfields' do
      expect(schema.compound_names).to contain_exactly(:contributors, :identifiers, :agent, :relationships)
    end

    it 'does not treat a plain scalar attribute as a compound' do
      expect(schema.compound_names).not_to include(:title)
    end
  end

  describe 'display mode (view: { display: card })' do
    describe '#inline_compound_names' do
      it 'excludes compounds declared as cards' do
        expect(schema.inline_compound_names).to contain_exactly(:contributors, :identifiers, :agent)
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
        .to eq(type: 'controlled', authority: 'contributor_role', values: nil, index_keys: [], display: false)
      expect(definition[:subfields]['given_name'])
        .to eq(type: 'string', authority: nil, values: nil,
               index_keys: %w[contributors_given_name_sim contributors_given_name_tesim], display: true)
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
        .to contain_exactly(:contributors, :identifiers, :agent, :relationships)
    end
  end
end
