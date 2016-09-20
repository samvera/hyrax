require "spec_helper"

RSpec.describe 'PowerConverter' do
  context '#convert_to_sipity_entity' do
    it 'will return the object if it is a Sipity::Entity' do
      object = Sipity::Entity.new
      expect(PowerConverter.convert_to_sipity_entity(object)).to eq(object)
    end

    it 'will return the object if it is a Sipity::Comment' do
      entity = Sipity::Entity.new
      object = Sipity::Comment.new(entity: entity)
      expect(PowerConverter.convert_to_sipity_entity(object)).to eq(entity)
    end

    context 'a Models::Work (because it will be processed)' do
      # This is poking knowledge over into the inner workings of Models::Work
      # but is a reasonable place to understand this.
      it 'will raise an exception if one has not been assigned' do
        object = build(:generic_work)
        expect { PowerConverter.convert_to_sipity_entity(object) }.to raise_error RuntimeError, "Can't create an entity until the model has been persisted"
      end
    end

    it 'will return the to_processing_entity if the object responds to the processing entity' do
      object = double(to_sipity_entity: :processing_entity)
      expect(PowerConverter.convert_to_sipity_entity(object)).to eq(:processing_entity)
    end

    it 'will raise an error if it cannot convert' do
      object = double
      expect { PowerConverter.convert_to_sipity_entity(object) }.to raise_error PowerConverter::ConversionError
    end
  end
end
