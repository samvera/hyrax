# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::PropertyAliasValidator do
  subject(:validator) { described_class.new(context) }
  let(:context) { Hyrax::FlexibleSchemaValidators::ValidationContext.new(profile: profile) }
  let(:warnings) { validator.violations.select(&:warning?).map(&:message) }
  let(:primary) { { 'indexing' => %w[shelf_mark_tesim facetable], 'data_type' => 'array' } }
  let(:profile) { { 'properties' => { 'shelf_mark' => primary, 'shelf_mark_monograph' => alias_entry } } }

  before { validator.validate! }

  context 'when an alias stores its values where its primary does' do
    let(:alias_entry) do
      { 'name' => 'shelf_mark', 'indexing' => %w[shelf_mark_tesim admin_only], 'data_type' => 'array',
        'available_on' => { 'class' => ['Monograph'] } }
    end

    it 'does not warn, even when the alias adds a role flag' do
      expect(warnings).to be_empty
    end
  end

  context 'when the profile has no entry keyed by the alias name' do
    let(:profile) { { 'properties' => { 'shelf_mark_monograph' => { 'name' => 'shelf_mark', 'indexing' => %w[shelf_mark_tesim] } } } }

    it 'warns that the alias has no primary' do
      expect(warnings).to contain_exactly(a_string_including('shelf_mark_monograph', 'shelf_mark'))
    end
  end

  context 'when an alias indexes into different Solr keys than its primary' do
    let(:alias_entry) { { 'name' => 'shelf_mark', 'indexing' => %w[monograph_shelf_tesim], 'data_type' => 'array' } }

    it 'warns that the alias stores its values elsewhere' do
      expect(warnings).to contain_exactly(a_string_including('shelf_mark_monograph', 'monograph_shelf_tesim'))
    end
  end

  context 'when an alias is single-valued and its primary is not' do
    let(:alias_entry) { { 'name' => 'shelf_mark', 'indexing' => %w[shelf_mark_tesim], 'data_type' => 'string' } }

    it 'warns that the alias reads a different number of values' do
      expect(warnings).to contain_exactly(a_string_including('shelf_mark_monograph', 'shelf_mark'))
    end
  end

  context 'when an alias allows one value by cardinality and its primary allows many' do
    let(:primary) { { 'indexing' => %w[shelf_mark_tesim], 'cardinality' => { 'minimum' => 0, 'maximum' => 5 } } }
    let(:alias_entry) { { 'name' => 'shelf_mark', 'indexing' => %w[shelf_mark_tesim], 'cardinality' => { 'maximum' => 1 } } }

    it 'warns that the alias reads a different number of values' do
      expect(warnings).to contain_exactly(a_string_including('shelf_mark_monograph', 'shelf_mark'))
    end
  end

  context 'when an alias declares multi_value where its primary declares an array' do
    let(:alias_entry) { { 'name' => 'shelf_mark', 'indexing' => %w[shelf_mark_tesim], 'multi_value' => true } }

    it 'does not warn' do
      expect(warnings).to be_empty
    end
  end

  context 'with compound sub-properties that share a generic name' do
    let(:profile) do
      { 'properties' => {
        'creator_name' => { 'name' => 'name', 'available_on' => { 'properties' => ['creators'] }, 'indexing' => %w[creators_name_tesim] },
        'contributor_name' => { 'name' => 'name', 'available_on' => { 'properties' => ['contributors'] }, 'indexing' => %w[contributors_name_tesim] }
      } }
    end

    it 'does not warn' do
      expect(warnings).to be_empty
    end
  end
end
