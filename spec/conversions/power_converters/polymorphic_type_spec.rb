require "spec_helper"

RSpec.describe 'PowerConverter', no_clean: true do
  describe '#convert_to_polymorphic_type' do
    it 'will convert an object that responds to #to_polymorphic_type' do
      object = double(to_polymorphic_type: :symbol)
      expect(PowerConverter.convert_to_polymorphic_type(object)).to eq(:symbol)
    end
    it 'will convert an ActiveRecord::Base object' do
      user = build(:user)
      expect(PowerConverter.convert_to_polymorphic_type(user)).to eq(user.class)
    end
    it 'will convert an object that responds to #base_class' do
      object = double(base_class: :symbol)
      expect(PowerConverter.convert_to_polymorphic_type(object)).to eq(:symbol)
    end

    it 'will fail to convert strings' do
      expect { PowerConverter.convert_to_polymorphic_type('hello') }.to raise_error(PowerConverter::ConversionError)
    end
  end
end
