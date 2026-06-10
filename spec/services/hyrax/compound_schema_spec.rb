# frozen_string_literal: true

RSpec.describe Hyrax::CompoundSchema do
  # These resources stand in for what the schema loaders produce: each compound
  # parent is a `hash` attribute whose meta carries the folded `subproperties:`
  # map (the loaders fold each compound's `available_on: { properties: [...] }` members into the
  # parent's meta) plus optional `groups:` label metadata. Each subproperty spec
  # carries its own `group`, `form` (cols/as), index_keys, etc.
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestResourceWithCompounds'
      end

      attribute :title, Valkyrie::Types::Array.of(Valkyrie::Types::String)
      attribute :contributors,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    'given_name' => { 'type' => 'string', 'group' => 'identity', 'form' => { 'cols' => 6 },
                                      'index_keys' => %w[contributors_given_name_sim contributors_given_name_tesim] },
                    'family_name' => { 'type' => 'string', 'group' => 'identity', 'form' => { 'cols' => 6 },
                                       'index_keys' => %w[contributors_family_name_tesim] },
                    'role_label' => { 'type' => 'controlled', 'authority' => 'contributor_role', 'group' => 'role', 'display' => false }
                  },
                  groups: { 'identity' => { 'label' => 'Identity' }, 'role' => { 'label' => 'Role' } }
                )
      attribute :identifiers,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    'value' => { 'type' => 'string' },
                    'identifier_type' => { 'type' => 'controlled', 'authority' => 'identifier_type' }
                  }
                )
      attribute :agent,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    'agent_name' => { 'type' => 'string' },
                    'agent_role' => { 'type' => 'controlled', 'values' => ['Author', { 'id' => 'ed', 'label' => 'Editor' }] }
                  }
                )
      attribute :relationships,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    'related_item' => { 'type' => 'work_or_url' },
                    'relationship_type' => { 'type' => 'controlled', 'authority' => 'relationship_type' }
                  },
                  display_label: { 'default' => 'Related works' },
                  view: { 'display' => 'card' }
                )
      # Required at the compound level (non-flexible `required: true`) with two
      # required sub-properties and one optional.
      attribute :required_compound,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  required: true,
                  subproperties: {
                    'item' => { 'type' => 'string', 'required' => true },
                    'kind' => { 'type' => 'string', 'required' => true },
                    'note' => { 'type' => 'string' }
                  }
                )
      # Required at the compound level via m3 minimum cardinality (flexible).
      attribute :cardinality_compound,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  cardinality: { 'minimum' => 1 },
                  subproperties: { 'value' => { 'type' => 'string' } }
                )
    end
  end

  subject(:schema) { described_class.for(resource_class) }

  describe '#compound_names' do
    it 'returns only the attributes that declare subproperties' do
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

  describe 'display_label' do
    it 'normalizes a declared display_label to a locale hash' do
      expect(schema.definition_for(:relationships)[:display_label]).to eq('default' => 'Related works')
    end

    it 'is nil when none is declared' do
      expect(schema.definition_for(:contributors)[:display_label]).to be_nil
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

    describe '#required_subproperty_keys' do
      it 'returns the sub-properties declared required: true' do
        expect(schema.required_subproperty_keys(:required_compound)).to eq(%w[item kind])
      end

      it 'is empty when no sub-property is required' do
        expect(schema.required_subproperty_keys(:relationships)).to eq([])
      end

      it 'is empty for a non-compound' do
        expect(schema.required_subproperty_keys(:title)).to eq([])
      end
    end

    it 'records required on the definition (subproperty + compound level)' do
      definition = schema.definition_for(:required_compound)
      expect(definition[:required]).to be true
      expect(definition[:subproperties]['item'][:required]).to be true
      expect(definition[:subproperties]['note'][:required]).to be false
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

  describe '#subproperty_keys' do
    it 'returns the ordered sub-property keys' do
      expect(schema.subproperty_keys(:contributors)).to eq(%w[given_name family_name role_label])
    end

    it 'is empty for a non-compound' do
      expect(schema.subproperty_keys(:title)).to eq([])
    end
  end

  describe '#definition_for' do
    it 'normalizes subproperties with type, authority, index_keys, display, group, cols and as' do
      definition = schema.definition_for(:contributors)
      expect(definition[:subproperties]['role_label'])
        .to eq(type: 'controlled', authority: 'contributor_role', values: nil, index_keys: [],
               display: false, required: false, group: 'role', cols: 6, as: nil)
      expect(definition[:subproperties]['given_name'])
        .to eq(type: 'string', authority: nil, values: nil,
               index_keys: %w[contributors_given_name_sim contributors_given_name_tesim],
               display: true, required: false, group: 'identity', cols: 6, as: nil)
    end

    it 'reads per-sub-property index_keys (literal Solr field names)' do
      expect(schema.definition_for(:contributors)[:subproperties]['family_name'][:index_keys])
        .to eq(%w[contributors_family_name_tesim])
    end

    it 'defaults a sub-property with no index declaration to no index_keys' do
      expect(schema.definition_for(:agent)[:subproperties]['agent_name'][:index_keys]).to eq([])
    end

    it 'defaults display to true and honors display: false' do
      expect(schema.definition_for(:contributors)[:subproperties]['given_name'][:display]).to be true
      expect(schema.definition_for(:contributors)[:subproperties]['role_label'][:display]).to be false
    end

    it 'defaults cols to 6 when no form placement is declared' do
      expect(schema.definition_for(:identifiers)[:subproperties]['value'][:cols]).to eq(6)
    end

    it 'normalizes an inline controlled-vocabulary values list to [label, id] pairs' do
      values = schema.definition_for(:agent)[:subproperties]['agent_role'][:values]
      expect(values).to eq([%w[Author Author], %w[Editor ed]])
    end

    it 'reconstructs groups from subproperty membership and the parent group labels' do
      groups = schema.definition_for(:contributors)[:groups]
      expect(groups).to eq([
                             { key: 'identity', label: 'Identity', fields: %w[given_name family_name] },
                             { key: 'role', label: 'Role', fields: %w[role_label] }
                           ])
    end

    it 'puts subproperties with no group in a single default (unlabeled) group' do
      groups = schema.definition_for(:identifiers)[:groups]
      expect(groups).to eq([{ key: nil, label: nil, fields: %w[value identifier_type] }])
    end
  end

  describe '.for' do
    it 'builds from a resource instance' do
      expect(described_class.for(resource_class.new).compound_names)
        .to contain_exactly(:contributors, :identifiers, :agent, :relationships,
                            :required_compound, :cardinality_compound)
    end
  end

  describe 'instance schema source ordering (singleton before class)' do
    # build_definitions is first-source-wins per name, so a flexible instance's
    # singleton schema (current version) must precede its class schema (frozen
    # at class-load) for a freshly-uploaded profile to win. See
    # #schema_sources_for.
    it 'lists the singleton schema before the class schema for an instance' do
      class_schema = double('class_schema')
      singleton_schema = double('singleton_schema')
      resource = double('resource',
                        class: double('klass', schema: class_schema),
                        singleton_class: double('singleton', schema: singleton_schema))

      sources = described_class.send(:schema_sources_for, resource)
      expect(sources).to eq([singleton_schema, class_schema])
    end

    it 'uses the class schema alone for a class argument (non-flexible)' do
      schema_obj = double('schema')
      klass = Class.new { define_singleton_method(:schema) { schema_obj } }
      expect(described_class.send(:schema_sources_for, klass)).to eq([schema_obj])
    end
  end

  describe '.for_solr_document' do
    # The attribute map a flexible schema loader returns for a version:
    # `{ name => dry_type_with_meta }` (with subproperties folded into the
    # parent meta) — the same shape SchemaLoader#attributes_for produces. Show
    # pages resolve compounds from this (via schema_version) without loading the
    # resource.
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
