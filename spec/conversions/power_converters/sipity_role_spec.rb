require 'spec_helper'

RSpec.describe 'PowerConverter', no_clean: true do
  context 'role' do
    it "will convert Sipity::Role" do
      object = Sipity::Role.new
      expect(PowerConverter.convert(object, to: :sipity_role)).to eq(object)
    end

    it "will convert a #to_sipity_role object" do
      object = double(to_sipity_role: Sipity::Role.new)
      expect(PowerConverter.convert(object, to: :sipity_role)).to eq(object.to_sipity_role)
    end

    it "will convert a string to a Sipity::Role if there exists a Sipity::Role with a name equal to the string" do
      Sipity::Role.create!(name: 'hello')
      expect(PowerConverter.convert('hello', to: :sipity_role)).to be_a(Sipity::Role)
    end

    it "will raise an exception if given a string and no Sipity::Role exists with that name" do
      expect { PowerConverter.convert('hello', to: :sipity_role) }.to raise_error(PowerConverter::ConversionError)
    end

    it "will convert a base object with composed attributes delegator" do
      base_object = Sipity::Role.new
      expect(PowerConverter.convert(base_object, to: :sipity_role)).to eq(base_object)
    end

    it 'will not convert an arbitrary object' do
      expect { PowerConverter.convert(double, to: :sipity_role) }.to raise_error(PowerConverter::ConversionError)
    end
  end
end
