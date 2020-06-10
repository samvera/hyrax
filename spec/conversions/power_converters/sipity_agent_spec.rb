# frozen_string_literal: true
require "spec_helper"

RSpec.describe 'PowerConverter' do
  context '#convert_to_sipity_agent' do
    it 'will convert a Sipity::Agent' do
      object = Sipity::Agent.new
      expect(PowerConverter.convert_to_sipity_agent(object)).to eq(object)
    end

    it 'will convert an object that responds to #to_sipity_agent' do
      object = double(to_sipity_agent: :a_sipity_agent)
      expect(PowerConverter.convert_to_sipity_agent(object)).to eq(:a_sipity_agent)
    end

    it 'will raise an exception if it cannot convert the given object' do
      object = double
      expect { PowerConverter.convert_to_sipity_agent(object) }.to raise_error(PowerConverter::ConversionError)
    end
  end
end
