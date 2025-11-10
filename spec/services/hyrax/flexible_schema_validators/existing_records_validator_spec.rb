# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::ExistingRecordsValidator do
  subject(:validator) { described_class.new(profile, required_classes, errors) }

  let(:profile) { {} }
  let(:required_classes) { ['AdminSetResource', 'CollectionResource', 'Hyrax::FileSet'] }
  let(:errors) { [] }

  before do
    stub_const('AdminSetResource', Class.new)
    stub_const('CollectionResource', Class.new)
    stub_const('Hyrax::FileSet', Class.new)
  end

  describe '#initialize' do
    it 'sets instance variables' do
      expect(validator.instance_variable_get(:@profile)).to eq(profile)
      expect(validator.instance_variable_get(:@required_classes)).to eq(required_classes)
      expect(validator.instance_variable_get(:@errors)).to eq(errors)
    end
  end

  describe '#validate!' do
    let(:profile) do
      { 'classes' => { 'GenericWorkResource' => { 'display_label' => 'Generic Work' } } }
    end

    before do
      stub_const('GenericWorkResource', Class.new)
      stub_const('ImageResource', Class.new)
      stub_const('Image', Class.new)

      # Stubbing Wings since the validator now depends on it.
      if Object.const_defined?('Wings')
        Rails.logger.warn('Wings is already defined, not stubbing.')
      else
        stub_const('Wings', Module.new)
        stub_const('Wings::ModelRegistry', Class.new)
      end

      allow(Wings::ModelRegistry).to receive(:lookup).and_call_original
      allow(Wings::ModelRegistry).to receive(:lookup).with(ImageResource).and_return(Image)

      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image'])
      allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(->(name) { "#{name}Resource".constantize })
      allow(Hyrax.query_service).to receive(:count_all_of_model).and_return(0)
    end

    it 'adds an error if a class with records is removed' do
      allow(Hyrax.query_service).to receive(:count_all_of_model).with(model: ImageResource).and_return(1)
      validator.validate!
      expect(errors).to include('Classes with existing records cannot be removed from the profile: ImageResource.')
    end

    it 'does not add an error when no classes have existing records' do
      validator.validate!
      expect(errors).to be_empty
    end

    it 'does not add an error if the counterpart class is present' do
      profile['classes'] = { 'Image' => {} } # Profile has 'Image', not 'ImageResource'
      allow(Hyrax.query_service).to receive(:count_all_of_model).with(model: ImageResource).and_return(1)
      validator.validate!
      expect(errors).to be_empty
    end

    it 'logs an error but does not fail if the query service raises an error' do
      allow(Rails.logger).to receive(:error)
      allow(Hyrax.query_service).to receive(:count_all_of_model).with(model: ImageResource).and_raise(StandardError, 'Database error')
      validator.validate!
      expect(Rails.logger).to have_received(:error).with('Error checking records for ImageResource: Database error')
      expect(errors).to be_empty
    end

    context 'when Wings is not defined' do
      before do
        hide_const('Wings')
      end

      it 'adds an error if a class with records is removed and no counterpart can be found' do
        allow(Hyrax.query_service).to receive(:count_all_of_model).with(model: ImageResource).and_return(1)
        validator.validate!
        expect(errors).to include('Classes with existing records cannot be removed from the profile: ImageResource.')
      end
    end
  end

  describe '#potential_existing_classes' do
    before do
      stub_const('GenericWorkResource', Class.new)
      stub_const('Image', Class.new) # A model without a Resource suffix
      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image'])

      resolver = lambda do |class_name|
        return Image if class_name == 'Image'
        "#{class_name}Resource".constantize
      end
      allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(resolver)
    end

    it 'includes the canonical model for each registered concern type' do
      classes = validator.send(:potential_existing_classes)
      expect(classes).to include(GenericWorkResource)
      expect(classes).to include(Image)
    end

    it 'includes required classes' do
      classes = validator.send(:potential_existing_classes)
      expect(classes).to include(AdminSetResource, CollectionResource, Hyrax::FileSet)
    end

    it 'removes duplicates' do
      # Make the resolver return the same class for two different inputs
      resolver = ->(_name) { GenericWorkResource }
      allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(resolver)

      classes = validator.send(:potential_existing_classes)
      expect(classes.count(GenericWorkResource)).to eq(1)
    end

    it 'gracefully handles unresolvable concerns' do
      allow(Rails.logger).to receive(:warn)
      resolver = lambda do |class_name|
        raise NameError, 'testing' if class_name == 'Image'
        "#{class_name}Resource".constantize
      end
      allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(resolver)

      validator.send(:potential_existing_classes)
      expect(Rails.logger).to have_received(:warn).with('Could not resolve model class for registered concern: Image')
    end
  end
end
