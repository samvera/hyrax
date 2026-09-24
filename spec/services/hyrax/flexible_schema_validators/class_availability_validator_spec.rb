# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::ClassAvailabilityValidator do
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
        validator.validate!
        expect(errors).to include('Invalid classes: InvalidWorkType, AnotherInvalidWorkType.')
        expect(errors).to include(a_string_starting_with("Mismatched Valkyrie classes found: 'GenericWorkResource' should be 'GenericWork'"))
      end
    end

    context 'when all classes are valid' do
      let(:profile) do
        { 'classes' => { 'GenericWorkResource' => { 'display_label' => 'Generic Work' } } }
      end

      it 'does not add an error' do
        stub_const('GenericWorkResource', Class.new)
        resolver = ->(_name) { GenericWorkResource }
        allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(resolver)

        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'when properties are nil' do
      let(:profile) { { 'classes' => { 'GenericWorkResource' => {} } } }

      it 'handles nil properties without error' do
        stub_const('GenericWorkResource', Class.new)
        resolver = ->(_name) { GenericWorkResource }
        allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(resolver)

        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with required classes' do
      let(:profile) { { 'classes' => { 'AdminSetResource' => {} } } }

      it 'excludes required classes from validation' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with Valkyrie model naming conventions' do
      before do
        stub_const('ImageResource', Class.new)
        stub_const('ScholarlyWork', Class.new)
        hide_const('ScholarlyWorkResource') # Ensure this is not defined for the test

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
        context 'and the profile uses the non-resource name' do
          let(:profile) { { 'classes' => { 'Image' => {} } } }

          it 'adds an error' do
            validator.validate!
            expect(errors).to include(a_string_starting_with("Mismatched Valkyrie classes found: 'Image' should be 'ImageResource'"))
          end
        end

        context 'and the profile uses the correct ...Resource name' do
          let(:profile) { { 'classes' => { 'ImageResource' => {} } } }

          it 'does not add an error' do
            validator.validate!
            expect(errors).to be_empty
          end
        end
      end

      context "when a Valkyrie model exists without a 'Resource' suffix" do
        let(:profile) { { 'classes' => { 'ScholarlyWork' => {} } } }

        it 'does not add an error' do
          validator.validate!
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
          validator.validate!
          expect(errors).to include(a_string_starting_with("Mismatched Valkyrie classes found"))
          expect(errors).to include('Invalid classes: InvalidWork.')
        end
      end

      context 'with collection and admin set classes beyond the configured ones' do
        let(:required_classes) { ['ConfiguredAdminSet', 'ConfiguredCollection', 'Hyrax::FileSet'] }

        let(:profile) do
          {
            'classes' => {
              'ConfiguredAdminSet' => { 'display_label' => 'Configured Admin Set' },
              'ConfiguredCollection' => { 'display_label' => 'Configured Collection' },
              'SupersededAdminSet' => { 'display_label' => 'Superseded Admin Set' },
              'SupersededCollection' => { 'display_label' => 'Superseded Collection' }
            }
          }
        end

        before do
          stub_const('ConfiguredAdminSet', Class.new(Hyrax::AdministrativeSet))
          stub_const('ConfiguredCollection', Class.new(Hyrax::PcdmCollection))
          stub_const('SupersededAdminSet', Class.new(Hyrax::AdministrativeSet))
          stub_const('SupersededCollection', Class.new(Hyrax::PcdmCollection))
        end

        it 'does not report the non-configured collection and admin set classes as invalid' do
          validator.validate!
          expect(errors).to be_empty
        end
      end
    end
  end
end
