# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::CompoundValidator do
  subject(:validator) { described_class.new(profile: profile, errors: errors) }
  let(:errors) { [] }

  def t(key, **opts)
    I18n.t("hyrax.flexible_schema_validators.compound_validator.errors.#{key}", **opts)
  end

  describe '#validate!' do
    context 'with a well-formed compound property' do
      let(:profile) do
        {
          'properties' => {
            'agent' => {
              'type' => 'hash',
              'subproperties' => {
                'title' => { 'type' => 'string' },
                'agent_name' => { 'type' => 'string', 'indexing' => %w[agent_name_tesim] },
                'agent_role' => { 'type' => 'controlled', 'values' => %w[Author Editor], 'indexing' => %w[agent_role_sim] }
              }
            }
          }
        }
      end

      it 'records no errors' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with a controlled sub-property that uses an authority instead of inline values' do
      let(:profile) do
        {
          'properties' => {
            'agent' => {
              'type' => 'hash',
              'subproperties' => { 'role' => { 'type' => 'controlled', 'authority' => 'agent_role' } }
            }
          }
        }
      end

      it 'is valid (authority satisfies the option-source requirement)' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with a controlled sub-property that declares neither authority nor values' do
      let(:profile) do
        {
          'properties' => {
            'agent' => {
              'type' => 'hash',
              'subproperties' => { 'role' => { 'type' => 'controlled' } }
            }
          }
        }
      end

      it 'records an error' do
        validator.validate!
        expect(errors).to include(t('controlled_without_source', property: 'agent', subproperty: 'role'))
      end
    end

    context 'with a top-level indexing declaration on the compound' do
      let(:profile) do
        {
          'properties' => {
            'agent' => {
              'type' => 'hash',
              'indexing' => %w[agent_tesim],
              'subproperties' => { 'agent_name' => { 'type' => 'string' } }
            }
          }
        }
      end

      it 'records an error that indexing belongs on sub-properties' do
        validator.validate!
        expect(errors).to include(t('top_level_indexing', property: 'agent'))
      end
    end

    context 'when subproperties is not a mapping' do
      let(:profile) do
        { 'properties' => { 'agent' => { 'type' => 'hash', 'subproperties' => %w[a b] } } }
      end

      it 'records an error' do
        validator.validate!
        expect(errors).to include(t('subproperties_not_hash', property: 'agent'))
      end
    end

    context 'when a sub-property config is not a mapping' do
      let(:profile) do
        { 'properties' => { 'agent' => { 'type' => 'hash', 'subproperties' => { 'name' => 'string' } } } }
      end

      it 'records an error' do
        validator.validate!
        expect(errors).to include(t('subproperty_not_hash', property: 'agent', subproperty: 'name', actual: 'String'))
      end
    end

    context 'with a hash property that is not a compound (no subproperties, e.g. redirects)' do
      let(:profile) do
        { 'properties' => { 'redirects' => { 'type' => 'hash' } } }
      end

      it 'ignores it (not a compound)' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with no compound properties at all' do
      let(:profile) { { 'properties' => { 'title' => { 'type' => 'string' } } } }

      it 'is silent' do
        validator.validate!
        expect(errors).to be_empty
      end
    end
  end
end
