# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::ClassReferenceValidator do
  subject(:validator) { described_class.new(context) }
  let(:context) do
    Hyrax::FlexibleSchemaValidators::ValidationContext.new(
      profile: profile, required_classes: required_classes
    )
  end

  let(:profile) { {} }
  let(:required_classes) { ['AdminSetResource', 'CollectionResource', 'Hyrax::FileSet'] }
  let(:errors) { validator.violations.map(&:message) }

  describe '#validate!' do
    let(:profile) do
      {
        'classes' => {
          'GenericWorkResource' => { 'display_label' => 'Generic Work' }
        },
        'properties' => {
          'title' => {
            'available_on' => {
              'class' => ['GenericWorkResource', 'UndefinedClass']
            }
          },
          'creator' => {
            'available_on' => {
              'class' => ['AnotherUndefinedClass']
            }
          }
        }
      }
    end

    it 'adds error for undefined classes' do
      validator.validate!
      expect(errors).to include('Classes referenced in `available_on` but not defined in `classes`: UndefinedClass, AnotherUndefinedClass.')
    end

    it 'does not add error when all referenced classes are defined' do
      profile['classes']['UndefinedClass'] = { 'display_label' => 'Undefined' }
      profile['classes']['AnotherUndefinedClass'] = { 'display_label' => 'Another Undefined' }

      validator.validate!
      expect(errors).to be_empty
    end

    it 'handles empty properties' do
      profile['properties'] = {}

      validator.validate!
      expect(errors).to be_empty
    end

    it 'handles nil properties' do
      profile['properties'] = nil

      validator.validate!
      expect(errors).to be_empty
    end
  end
end
