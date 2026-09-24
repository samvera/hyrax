# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidatorService, :clean_repo do
  subject(:service) { described_class.new(profile: profile) }
  let(:profile) { YAML.safe_load_file(yaml) }
  let(:yaml) { Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml').to_s }

  before do
    allow_any_instance_of(Hyrax::FlexibleSchemaValidatorService).to receive(:required_classes).and_return(['AdminSet', 'Collection', 'FileSet'])
  end

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
          expect(service.errors).to include "Missing required classes: AdminSet, Collection, FileSet."
        end
      end

      context 'when it has invalid classes' do
        before do
          profile['classes']['InvalidWorkType'] = { 'display_label' => 'Invalid Work Type' }
          profile['properties']['title']['available_on']['class'] = ['AnotherInvalidWorkType']
          service.validate!
        end

        it 'is invalid' do
          expect(service.errors).to include "Invalid classes: InvalidWorkType, AnotherInvalidWorkType."
        end
      end

      context 'when a property is missing an available_on' do
        before do
          profile['properties']['title']['available_on']['class'] = nil
          profile['properties']['creator'].delete('available_on')
          service.validate!
        end

        it 'is invalid' do
          # GenericWork is still covered for `title` via the title_primary and title_alternative
          # name aliases in the fixture profile, so it is not listed as missing.
          expect(service.errors).to contain_exactly(
            "Schema error at `/properties/title/available_on/class`: Invalid value `nil` for type `array`.",
            "Schema error at `/properties/creator`: Missing required properties: 'available_on'.",
            "Property 'title' must be available on all classes, but is missing from: AdminSet, " \
            "Collection, FileSet, Monograph.",
            "Property 'creator' must be available on all classes, but is missing from: AdminSet, " \
            "Collection, FileSet, GenericWork, Monograph."
          )
        end
      end

      context 'when a property is missing a range' do
        before do
          profile['properties']['title']['range'] = nil
          profile['properties']['creator'].delete('range')
          service.validate!
        end

        it 'reports both properties' do
          expect(service.errors).to contain_exactly(
            'Schema error at `/properties/title/range`: Invalid value `nil` for type `string`.',
            "Schema error at `/properties/creator`: Missing required properties: 'range'."
          )
        end
      end

      context 'when the label property is misconfigured' do
        context 'when it is missing' do
          before do
            profile['properties'].delete('label')
            service.validate!
          end

          it 'is invalid' do
            expect(service.errors).to include 'A `label` property is required.'
          end
        end

        context 'when it is not available on FileSet' do
          before do
            profile['properties']['label']['available_on']['class'] = ['GenericWork']
            service.validate!
          end

          it 'is invalid' do
            expect(service.errors).to include 'Label must be available on FileSet.'
          end
        end

        context 'when it is available on Hyrax::FileSet and other classes' do
          before do
            profile['properties']['label']['available_on']['class'] = ['FileSet', 'GenericWork']
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
        profile['classes'].delete('GenericWork')
        service.validate!
      end

      it 'is invalid' do
        expect(service.errors).to include(
          'Classes referenced in `available_on` but not defined in `classes`: GenericWork.'
        )
      end
    end
    context 'when a property declares editor_only in its indexing array' do
      before do
        profile['properties']['title']['indexing'] = ['title_sim', 'title_tesim', 'editor_only']
        service.validate!
      end

      it 'is valid' do
        expect(service.errors).to be_empty
      end
    end

    context 'when the repository already contains records of a class the profile removes' do
      before do
        allow(Hyrax.query_service).to receive(:count_all_of_model).and_return(0)
        allow(Hyrax.query_service).to receive(:count_all_of_model)
          .with(model: GenericWork).and_return(1)

        profile['classes'].delete('GenericWork')
        profile['properties'].each_value do |prop_details|
          prop_details.dig('available_on', 'class')&.delete('GenericWork')
        end

        service.validate!
      end

      it 'is invalid' do
        expect(service.errors).to include(
          'Classes with existing records cannot be removed from the profile: GenericWork.'
        )
      end
    end
  end

  describe 'the configured validator list' do
    let(:run_order) { [] }

    # Each validator appends its own name, so the assertions read on the order
    # the service ran them in.
    def recording_validator(name)
      log = run_order
      Class.new(Hyrax::FlexibleSchemaValidators::BaseValidator) do
        define_method(:validate!) { log << name }
      end
    end

    it 'runs each configured validator in the order it is listed' do
      allow(Hyrax.config).to receive(:flexible_schema_validators)
        .and_return([recording_validator(:first), recording_validator(:second)])

      service.validate!

      expect(run_order).to eq [:first, :second]
    end

    it 'resolves a validator registered by name' do
      stub_const('NamedValidator', recording_validator(:named))
      allow(Hyrax.config).to receive(:flexible_schema_validators).and_return(['NamedValidator'])

      service.validate!

      expect(run_order).to eq [:named]
    end

    it 'reports what an app-registered validator finds' do
      app_validator = Class.new(Hyrax::FlexibleSchemaValidators::BaseValidator) do
        def validate!
          add_error 'the app said no'
          add_warning 'the app is unsure'
        end
      end
      allow(Hyrax.config).to receive(:flexible_schema_validators).and_return([app_validator])

      service.validate!

      expect(service.errors).to contain_exactly('the app said no')
      expect(service.warnings).to contain_exactly('the app is unsure')
    end
  end

  describe 'validator independence' do
    # No validator may depend on another having run, so that an app can reorder
    # or drop entries in Hyrax.config.flexible_schema_validators. A validator
    # that consults another's findings fails here rather than in the app that
    # reorders the list. The profile needs one error and one warning for the
    # two runs to have something to disagree about.
    let(:broken_profile) do
      profile['properties'].delete('label')
      profile['properties']['subject_faceted'] = {
        'available_on' => { 'class' => ['GenericWork'] },
        'indexing' => ['subject_faceted_tesim'],
        'view' => { 'render_as' => 'faceted' }
      }
      profile
    end

    def messages_running(validators)
      allow(Hyrax.config).to receive(:flexible_schema_validators).and_return(validators)
      service = described_class.new(profile: Marshal.load(Marshal.dump(broken_profile)))
      service.validate!
      [service.errors, service.warnings]
    end

    it 'finds the same problems whatever order the validators run in' do
      forward_errors, forward_warnings = messages_running(Hyrax.config.flexible_schema_validators)
      reversed_errors, reversed_warnings = messages_running(Hyrax.config.flexible_schema_validators.reverse)

      expect(forward_errors).not_to be_empty
      expect(forward_warnings).not_to be_empty
      expect(reversed_errors).to match_array(forward_errors)
      expect(reversed_warnings).to match_array(forward_warnings)
    end
  end
end
