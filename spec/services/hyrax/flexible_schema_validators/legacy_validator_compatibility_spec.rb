# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::LegacyValidatorCompatibility do
  subject(:validator) { validator_class.new(profile, errors) }

  let(:validator_class) do
    Class.new(Hyrax::FlexibleSchemaValidators::BaseValidator) do
      def validate!
        add_error 'an error'
        add_warning 'a warning'
      end
    end
  end

  let(:profile) { { 'properties' => { 'title' => { 'type' => 'string' } } } }
  let(:errors) { [] }
  let(:warnings) { [] }

  before { allow(Hyrax.deprecator).to receive(:warn) }

  describe 'constructing a validator the old way' do
    it 'warns that the argument list is going away' do
      validator

      expect(Hyrax.deprecator).to have_received(:warn).with(/deprecated/)
    end

    context 'with the profile and an errors array' do
      it 'still fills the array it was handed' do
        validator.validate!

        expect(errors).to contain_exactly('an error')
      end

      it 'also reports through violations' do
        validator.validate!

        expect(validator.violations.map(&:message)).to contain_exactly('an error', 'a warning')
      end
    end

    context 'with the profile and a warnings array, on a warning-only validator' do
      subject(:validator) { Hyrax::FlexibleSchemaValidators::RenderAsValidator.new(profile, warnings) }

      let(:profile) do
        { 'properties' => { 'title' => { 'view' => { 'render_as' => 'faceted' }, 'indexing' => [] } } }
      end

      it 'fills the array it was handed rather than treating it as errors' do
        validator.validate!

        expect(warnings).not_to be_empty
      end

      it 'records the warning as a warning' do
        validator.validate!

        expect(validator.violations).to all(be_warning)
      end
    end

    context 'with the profile, required classes, and an errors array' do
      subject(:validator) { validator_class.new(profile, ['AdminSet'], errors) }

      it 'reads the required classes' do
        expect(validator.send(:required_classes)).to eq ['AdminSet']
      end
    end

    context 'with keyword arguments' do
      subject(:validator) { validator_class.new(profile: profile, errors: errors, warnings: warnings) }

      it 'sorts the messages into the arrays it was handed' do
        validator.validate!

        expect(errors).to contain_exactly('an error')
        expect(warnings).to contain_exactly('a warning')
      end
    end

    context 'with a schemer first' do
      subject(:validator) { validator_class.new(schemer, profile, errors) }

      let(:schemer) { JSONSchemer.schema({ 'type' => 'object' }) }

      it 'reads the schemer' do
        expect(validator.send(:schemer)).to eq schemer
      end

      it 'reads the profile' do
        expect(validator.send(:profile)).to eq profile
      end
    end
  end

  describe 'an override that appends to the message ivars' do
    subject(:validator) { decorated_class.new(context) }

    let(:context) { Hyrax::FlexibleSchemaValidators::ValidationContext.new(profile: profile) }

    let(:decorated_class) do
      Class.new(Hyrax::FlexibleSchemaValidators::BaseValidator).tap do |klass|
        klass.prepend(Module.new do
          def validate!
            @warnings << 'decorated warning'
            @errors << 'decorated error'
          end
        end)
      end
    end

    it 'records what the override appends' do
      validator.validate!

      expect(validator.violations.map(&:message))
        .to contain_exactly('decorated warning', 'decorated error')
    end

    it 'keeps the severity each ivar implies' do
      validator.validate!

      expect(validator.violations.select(&:warning?).map(&:message)).to eq ['decorated warning']
      expect(validator.violations.select(&:error?).map(&:message)).to eq ['decorated error']
    end

    it 'does not warn, since the ivars are not deprecated' do
      validator.validate!

      expect(Hyrax.deprecator).not_to have_received(:warn)
    end

    it 'reaches the service that runs it' do
      stub_const('DecoratedValidator', decorated_class)
      allow(Hyrax.config).to receive(:flexible_schema_validators).and_return(['DecoratedValidator'])

      service = Hyrax::FlexibleSchemaValidatorService.new(profile: profile)
      service.validate!

      expect(service.warnings).to eq ['decorated warning']
      expect(service.errors).to eq ['decorated error']
    end
  end
end
