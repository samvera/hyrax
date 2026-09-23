# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::RenderAsValidator do
  subject(:validator) { described_class.new(context) }
  let(:context) { Hyrax::FlexibleSchemaValidators::ValidationContext.new(profile: profile) }
  let(:warnings) { validator.violations.map(&:message) }

  describe 'render_as: linked' do
    context 'on a searchable, uncontrolled property' do
      let(:profile) do
        { 'properties' => {
          'creator' => { 'controlled_values' => { 'sources' => ['null'] },
                         'indexing' => ['creator_tesim'],
                         'view' => { 'render_as' => 'linked' } }
        } }
      end

      it 'does not warn' do
        validator.validate!
        expect(warnings).to be_empty
      end
    end

    context 'on a property that indexes no searchable field' do
      let(:profile) do
        { 'properties' => {
          'creator' => { 'indexing' => ['creator_sim'], 'view' => { 'render_as' => 'linked' } }
        } }
      end

      it 'warns that the generated search has no field to query' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('creator', '_tesim'))
      end
    end

    context 'on a property with no indexing at all' do
      let(:profile) do
        { 'properties' => { 'creator' => { 'view' => { 'render_as' => 'linked' } } } }
      end

      it 'warns' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('creator', '_tesim'))
      end
    end

    context 'on a controlled property' do
      let(:profile) do
        { 'properties' => {
          'resource_type' => { 'controlled_values' => { 'sources' => ['resource_types'] },
                               'indexing' => ['resource_type_tesim'],
                               'view' => { 'render_as' => 'linked' } }
        } }
      end

      it 'warns that the search looks for a label in a field holding ids' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('resource_type', 'render_as: linked'))
      end
    end

    context 'on a controlled property that is also facetable' do
      let(:profile) do
        { 'properties' => {
          'resource_type' => { 'controlled_values' => { 'sources' => ['resource_types'] },
                               'indexing' => ['resource_type_sim', 'resource_type_tesim', 'facetable'],
                               'view' => { 'render_as' => 'linked' } }
        } }
      end

      it 'warns that the facet link is built and then discarded' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('resource_type', 'facet'))
      end
    end

    context 'on a controlled property declared under a name surrogate' do
      let(:profile) do
        { 'properties' => {
          'alternate_resource_type' => { 'name' => 'resource_type',
                                         'controlled_values' => { 'sources' => ['resource_types'] },
                                         'indexing' => ['resource_type_sim', 'resource_type_tesim', 'facetable'],
                                         'view' => { 'render_as' => 'linked' } }
        } }
      end

      it 'names the property as the profile declares it' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('alternate_resource_type'))
      end
    end
  end

  describe 'render_as: faceted' do
    context 'on a property indexing its _sim field' do
      let(:profile) do
        { 'properties' => {
          'subject' => { 'indexing' => ['subject_sim', 'subject_tesim'],
                         'view' => { 'render_as' => 'faceted' } }
        } }
      end

      it 'does not warn' do
        validator.validate!
        expect(warnings).to be_empty
      end
    end

    context 'on a property that indexes no _sim field' do
      let(:profile) do
        { 'properties' => {
          'subject' => { 'indexing' => ['subject_tesim'], 'view' => { 'render_as' => 'faceted' } }
        } }
      end

      it 'warns that the facet link points at an unindexed field' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('subject', '_sim'))
      end
    end

    context 'on a property whose _sim field is named by a surrogate' do
      let(:profile) do
        { 'properties' => {
          'alternate_resource_type' => { 'name' => 'resource_type',
                                         'indexing' => ['resource_type_sim'],
                                         'view' => { 'render_as' => 'faceted' } }
        } }
      end

      it 'resolves the _sim name through the surrogate and does not warn' do
        validator.validate!
        expect(warnings).to be_empty
      end
    end
  end

  describe 'render_as values that resolve labels themselves' do
    let(:profile) do
      { 'properties' => {
        'license' => { 'controlled_values' => { 'sources' => ['licenses'] },
                       'indexing' => ['license_tesim'],
                       'view' => { 'render_as' => 'external_link' } },
        'rights_statement' => { 'controlled_values' => { 'sources' => ['rights_statements'] },
                                'indexing' => ['rights_statement_tesim'],
                                'view' => { 'render_as' => 'rights_statement' } }
      } }
    end

    it 'does not warn' do
      validator.validate!
      expect(warnings).to be_empty
    end
  end

  describe 'a property with no render_as' do
    let(:profile) do
      { 'properties' => {
        'audience' => { 'controlled_values' => { 'sources' => ['audience'] },
                        'indexing' => ['audience_sim', 'audience_tesim', 'facetable'] }
      } }
    end

    it 'does not warn' do
      validator.validate!
      expect(warnings).to be_empty
    end
  end

  describe 'a profile with no properties' do
    let(:profile) { {} }

    it 'does not raise' do
      expect { validator.validate! }.not_to raise_error
    end
  end
end
