# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidatorService do
  subject(:service) { described_class.new(profile: profile) }
  let(:profile) { YAML.safe_load_file(yaml) }
  let(:yaml) { Rails.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml').to_s }

  describe '#validate' do
    context 'with a valid schema' do
      before { service.validate! }

      it 'does not have any errors' do
        expect(service.errors).to be_empty
      end
    end

    context 'with an invalid schema' do
      context 'when it does not have the required classes' do
        before do
          service.required_classes.each do |klass|
            profile['classes'].delete(klass)
          end
          service.validate!
        end

        it 'is invalid' do
          expect(service.errors.first).to eq "Missing required classes: #{service.required_classes.join(', ')}."
        end
      end

      context 'when it has invalid classes' do
        before do
          profile['classes']['InvalidWorkType'] = { 'display_label' => 'Invalid Work Type' }
          profile['properties']['title']['available_on']['class'] = ['AnotherInvalidWorkType']
          service.validate!
        end

        it 'is invalid' do
          expect(service.errors.first).to eq "Invalid classes: InvalidWorkType, AnotherInvalidWorkType."
        end
      end

      context 'when a property is missing an available_on' do
        before do
          profile['properties']['title']['available_on']['class'] = nil
          profile['properties']['creator'].delete('available_on')
          service.validate!
        end

        it 'is invalid' do
          expect(service.errors).to contain_exactly(
            "Schema error at `/properties/title/available_on/class`: Invalid value `nil` for type `array`.",
            "Schema error at `/properties/creator`: Missing required properties: 'available_on'.",
            "Property 'title' must be available on all classes, but is missing from: AdminSetResource, " \
            "CollectionResource, Hyrax::FileSet, GenericWorkResource, ImageResource, EtdResource, OerResource.",
            "Property 'creator' must be available on all classes, but is missing from: AdminSetResource, " \
            "CollectionResource, Hyrax::FileSet, GenericWorkResource, ImageResource, EtdResource, OerResource."
          )
        end
      end

      context 'when a property is missing a range' do
        before do
          profile['properties']['title']['range'] = nil
          profile['properties']['creator'].delete('range')
          service.validate!
        end

        it 'is invalid' do
          expect(service.errors.size).to eq 2
          expect(service.errors.first).to eq 'Schema error at `/properties/title/range`: Invalid value `nil` for type `string`.'
          expect(service.errors.last).to eq "Schema error at `/properties/creator`: Missing required properties: 'range'."
        end
      end

      context 'when the label property is misconfigured' do
        context 'when it is missing' do
          before do
            profile['properties'].delete('label')
            service.validate!
          end

          it 'is invalid' do
            expect(service.errors.first).to eq 'A `label` property is required.'
          end
        end

        context 'when it is not available on Hyrax::FileSet' do
          before do
            profile['properties']['label']['available_on']['class'] = ['GenericWorkResource']
            service.validate!
          end

          it 'is invalid' do
            expect(service.errors.first).to eq 'Label must be available on Hyrax::FileSet.'
          end
        end

        context 'when it is available on Hyrax::FileSet and other classes' do
          before do
            profile['properties']['label']['available_on']['class'] = ['Hyrax::FileSet', 'GenericWorkResource']
            service.validate!
          end

          it 'is valid' do
            expect(service.errors).to be_empty
          end
        end
      end
    end

    context 'when a property references a class not defined in the classes section' do
      before do
        # Remove a valid class definition but leave references in `available_on`
        profile['classes'].delete('GenericWorkResource')
        service.validate!
      end

      it 'is invalid' do
        expect(service.errors).to include(
          'Classes referenced in `available_on` but not defined in `classes`: GenericWorkResource.'
        )
      end
    end
    context 'when the repository already contains records of a class the profile removes' do
      before do
        allow(Hyrax.query_service).to receive(:count_all_of_model).and_return(0)
        allow(Hyrax.query_service).to receive(:count_all_of_model)
          .with(model: ImageResource).and_return(1)

        profile['classes'].delete('ImageResource')
        profile['properties'].each_value do |prop_details|
          prop_details.dig('available_on', 'class')&.delete('ImageResource')
        end

        service.validate!
      end

      it 'is invalid' do
        expect(service.errors).to include(
          'Classes with existing records cannot be removed from the profile: ImageResource.'
        )
      end
    end
  end
end
