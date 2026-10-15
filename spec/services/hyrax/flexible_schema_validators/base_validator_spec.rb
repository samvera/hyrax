# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::BaseValidator do
  subject(:validator) { validator_class.new(context) }

  let(:context) { Hyrax::FlexibleSchemaValidators::ValidationContext.new(profile: profile) }
  let(:profile) { { 'properties' => { 'title' => { 'type' => 'string' } } } }
  let(:validator_class) { Class.new(described_class) }

  describe '#validate!' do
    it 'raises until a subclass implements it' do
      expect { validator.validate! }.to raise_error(NotImplementedError)
    end
  end

  describe '#violations' do
    let(:validator_class) do
      Class.new(described_class) do
        def validate!
          add_error 'a literal error'
          add_warning 'a literal warning'
        end
      end
    end

    before { validator.validate! }

    it 'records what the validator found, in the order it was recorded' do
      expect(validator.violations.map(&:message))
        .to eq ['a literal error', 'a literal warning']
    end

    it 'tags each violation with its severity' do
      expect(validator.violations.map(&:severity)).to eq [:error, :warning]
    end

    it 'starts empty' do
      expect(validator_class.new(context).violations).to eq []
    end
  end

  describe 'message resolution' do
    let(:validator_class) do
      Class.new(described_class) do
        def self.i18n_scope
          'hyrax.flexible_schema_validators.render_as_validator'
        end

        def validate!
          add_warning(:requires_sim_field, property: 'subject')
        end
      end
    end

    it 'looks a symbol up under the validator i18n scope' do
      validator.validate!

      expect(validator.violations.first.message)
        .to eq I18n.t('hyrax.flexible_schema_validators.render_as_validator.warnings.requires_sim_field',
                      property: 'subject')
    end
  end

  describe '.i18n_scope' do
    before do
      stub_const('Hyrax::FlexibleSchemaValidators::ExampleThingValidator', Class.new(described_class))
    end

    it 'derives the scope from the validator name' do
      expect(Hyrax::FlexibleSchemaValidators::ExampleThingValidator.i18n_scope)
        .to eq 'hyrax.flexible_schema_validators.example_thing_validator'
    end
  end

  describe 'context delegation' do
    let(:validator_class) do
      Class.new(described_class) do
        def validate!
          properties.each_key { |name| add_error("saw #{name}") }
        end
      end
    end

    it 'exposes the context readers to subclasses' do
      validator.validate!

      expect(validator.violations.map(&:message)).to eq ['saw title']
    end
  end
end
