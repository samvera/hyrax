# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::CoreMetadataValidator do
  subject(:service) { described_class.new(profile: profile, errors: errors) }
  let(:profile) { YAML.safe_load_file(yaml) }
  let(:yaml) { Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml').to_s }
  let(:errors) { [] }

  describe '#validate!' do
    context 'with a valid schema' do
      let(:profile) do
        {
          'classes' => { 'TestClass' => { 'display_label' => 'Test' } },
          'properties' => {
            'title' => {
              'data_type' => 'array',
              'cardinality' => { 'minimum' => 1 },
              'property_uri' => 'http://purl.org/dc/terms/title',
              'indexing' => ['title_sim', 'title_tesim'],
              'available_on' => { 'class' => ['TestClass'] }
            },
            'date_modified' => {
              'property_uri' => 'http://purl.org/dc/terms/modified',
              'available_on' => { 'class' => ['TestClass'] }
            },
            'date_uploaded' => {
              'property_uri' => 'http://purl.org/dc/terms/dateSubmitted',
              'available_on' => { 'class' => ['TestClass'] }
            },
            'depositor' => {
              'property_uri' => 'http://id.loc.gov/vocabulary/relators/dpt',
              'indexing' => ['depositor_ssim', 'depositor_tesim'],
              'available_on' => { 'class' => ['TestClass'] }
            },
            'creator' => {
              'data_type' => 'array',
              'property_uri' => 'http://purl.org/dc/elements/1.1/creator',
              'indexing' => ['creator_sim', 'creator_tesim'],
              'available_on' => { 'class' => ['TestClass'] }
            }
          }
        }
      end

      before { service.validate! }

      it 'does not have any errors' do
        expect(errors).to be_empty
      end
    end

    context 'when keyword data_type is incorrect' do
      let(:profile) do
        {
          'classes' => { 'TestClass' => { 'display_label' => 'Test' } },
          'properties' => {
            'keyword' => {
              'data_type' => 'string', # This should be 'array'
              'available_on' => { 'class' => ['TestClass'] }
            }
          }
        }
      end

      before { service.validate! }

      it 'is invalid' do
        expect(errors).to include("Property 'keyword' must have data_type set to 'array'.")
      end
    end

    context 'when core metadata properties are misconfigured' do
      context 'when a required property is missing' do
        before do
          profile['properties'].delete('depositor')
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include('Missing required property: depositor.')
        end
      end

      context 'when the creator property is missing' do
        before do
          profile['properties'].delete('creator')
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include('Missing required property: creator.')
        end
      end

      context 'when creator data_type is incorrect' do
        before do
          profile['properties']['creator']['data_type'] = 'string'
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include("Property 'creator' must have data_type set to 'array'.")
        end
      end

      context 'when data_type is incorrect' do
        let(:profile) do
          {
            'classes' => { 'TestClass' => { 'display_label' => 'Test' } },
            'properties' => {
              'title' => {
                'data_type' => nil, # This should be 'array'
                'available_on' => { 'class' => ['TestClass'] }
              }
            }
          }
        end

        before { service.validate! }

        it 'is invalid' do
          expect(errors).to include("Property 'title' must have data_type set to 'array'.")
        end
      end

      context 'when indexing is missing keys' do
        before do
          profile['properties']['depositor']['indexing'] = ['depositor_tesim']
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include("Property 'depositor' is missing required indexing: depositor_ssim.")
        end
      end

      context 'when predicate (property_uri) is incorrect' do
        before do
          profile['properties']['title']['property_uri'] = 'http://example.com/wrong-predicate'
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include("Property 'title' must have property_uri set to http://purl.org/dc/terms/title.")
        end
      end

      context 'when a property is not available on all classes' do
        before do
          profile['properties'].each_value do |prop_details|
            prop_details.dig('available_on', 'class')&.delete('GenericWork')
          end

          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include("Property 'title' must be available on all classes, but is missing from: GenericWork.")
        end
      end

      context 'when title is not required' do
        context 'because `cardinality.minimum` is 0' do
          before do
            profile['properties']['title']['cardinality']['minimum'] = '0'
            service.validate!
          end

          it 'is invalid' do
            expect(errors).to include("Property 'title' must have a cardinality minimum of at least 1.")
          end
        end

        context 'because `cardinality` is missing' do
          before do
            profile['properties']['title'].delete('cardinality')
            service.validate!
          end

          it 'is invalid' do
            expect(errors).to include("Property 'title' must have a cardinality minimum of at least 1.")
          end
        end
      end
    end
  end
end
