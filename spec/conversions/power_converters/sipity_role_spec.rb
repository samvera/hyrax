# frozen_string_literal: true
RSpec.describe 'PowerConverter' do
  context 'role' do
    it "converts Sipity::Role" do
      object = Sipity::Role.new
      expect(PowerConverter.convert(object, to: :sipity_role)).to eq(object)
    end

    it "converts a #to_sipity_role object" do
      object = double(to_sipity_role: Sipity::Role.new)
      expect(PowerConverter.convert(object, to: :sipity_role)).to eq(object.to_sipity_role)
    end

    it "converts a string to a Sipity::Role if there exists a Sipity::Role with a name equal to the string" do
      Sipity::Role.create!(name: 'hello')
      expect(PowerConverter.convert('hello', to: :sipity_role)).to be_a(Sipity::Role)
    end

    it "creates a new role if given a string and no Sipity::Role exists with that name" do
      expect { PowerConverter.convert('hello', to: :sipity_role) }.to change { Sipity::Role.count }.by(1)
    end

    it "converts a base object with composed attributes delegator" do
      base_object = Sipity::Role.new
      expect(PowerConverter.convert(base_object, to: :sipity_role)).to eq(base_object)
    end

    it 'does not convert an arbitrary object' do
      expect { PowerConverter.convert(double, to: :sipity_role) }.to raise_error(PowerConverter::ConversionError)
    end
  end
end
