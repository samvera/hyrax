# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::ClassValidator do
  subject(:validator) { described_class.new(profile, required_classes, errors) }

  let(:profile) { {} }
  let(:required_classes) { ['AdminSetResource', 'CollectionResource', 'Hyrax::FileSet'] }
  let(:errors) { [] }

  describe '#initialize' do
    it 'sets instance variables' do
      expect(validator.instance_variable_get(:@profile)).to eq(profile)
      expect(validator.instance_variable_get(:@required_classes)).to eq(required_classes)
      expect(validator.instance_variable_get(:@errors)).to eq(errors)
    end
  end

  describe '#validate_availability!' do
    before do
      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image', 'ScholarlyWork'])
    end

    context 'with invalid class names' do
      let(:profile) do
        {
          'classes' => {
            'GenericWorkResource' => { 'display_label' => 'Generic Work' },
            'InvalidWorkType' => { 'display_label' => 'Invalid Work' }
          },
          'properties' => {
            'title' => { 'available_on' => { 'class' => ['AnotherInvalidWorkType'] } }
          }
        }
      end

      it 'adds an error for all invalid classes' do
        validator.validate_availability!
        expect(errors).to contain_exactly('Invalid classes: InvalidWorkType, AnotherInvalidWorkType.')
      end
    end

    context 'when all classes are valid' do
      let(:profile) do
        { 'classes' => { 'GenericWorkResource' => { 'display_label' => 'Generic Work' } } }
      end

      it 'does not add an error' do
        validator.validate_availability!
        expect(errors).to be_empty
      end
    end

    context 'when properties are nil' do
      let(:profile) { { 'classes' => { 'GenericWorkResource' => {} } } }

      it 'handles nil properties without error' do
        validator.validate_availability!
        expect(errors).to be_empty
      end
    end

    context 'with required classes' do
      let(:profile) { { 'classes' => { 'AdminSetResource' => {} } } }

      it 'excludes required classes from validation' do
        validator.validate_availability!
        expect(errors).to be_empty
      end
    end

    context 'with Valkyrie model naming conventions' do
      before do
        stub_const('ImageResource', Class.new)
        stub_const('ScholarlyWork', Class.new)
        hide_const('ScholarlyWorkResource') # Ensure this is not defined for the test

        # Mock the resolver to simulate production behavior for our test cases
        resolver = lambda do |class_name|
          resource_name = "#{class_name}Resource"
          begin
            resource_name.constantize
          rescue NameError
            class_name.constantize # Fallback to the base name if no ...Resource variant exists
          end
        end
        allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(resolver)
      end

      context 'when a ...Resource model exists' do
        it 'adds an error if the profile uses the non-resource name' do
          profile = { 'classes' => { 'Image' => {} } }
          validator = described_class.new(profile, required_classes, errors)
          validator.validate_availability!
          expect(errors).to include(a_string_starting_with("Mismatched Valkyrie classes found: 'Image' should be 'ImageResource'"))
        end

        it 'does not add an error if the profile uses the correct ...Resource name' do
          profile = { 'classes' => { 'ImageResource' => {} } }
          validator = described_class.new(profile, required_classes, errors)
          validator.validate_availability!
          expect(errors).to be_empty
        end
      end

      context "when a Valkyrie model exists without a 'Resource' suffix" do
        it 'does not add an error' do
          profile = { 'classes' => { 'ScholarlyWork' => {} } }
          validator = described_class.new(profile, required_classes, errors)
          validator.validate_availability!
          expect(errors).to be_empty
        end
      end

      context 'with a mix of invalid and mismatched classes' do
        let(:profile) do
          {
            'classes' => {
              'Image' => { 'display_label' => 'Image' },
              'InvalidWork' => { 'display_label' => 'Invalid Work' }
            }
          }
        end

        it 'reports both errors' do
          validator.validate_availability!
          expect(errors).to include(a_string_starting_with("Mismatched Valkyrie classes found"))
          expect(errors).to include('Invalid classes: InvalidWork.')
        end
      end
    end
  end

  describe '#validate_references!' do
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
      validator.validate_references!
      expect(errors).to include('Classes referenced in `available_on` but not defined in `classes`: UndefinedClass, AnotherUndefinedClass.')
    end

    it 'does not add error when all referenced classes are defined' do
      profile['classes']['UndefinedClass'] = { 'display_label' => 'Undefined' }
      profile['classes']['AnotherUndefinedClass'] = { 'display_label' => 'Another Undefined' }

      validator.validate_references!
      expect(errors).to be_empty
    end

    it 'handles empty properties' do
      profile['properties'] = {}

      validator.validate_references!
      expect(errors).to be_empty
    end

    it 'handles nil properties' do
      profile['properties'] = nil

      validator.validate_references!
      expect(errors).to be_empty
    end
  end
end
