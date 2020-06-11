# frozen_string_literal: true
require "spec_helper"

RSpec.describe 'PowerConverter' do
  context '#convert_to_sipity_action_name' do
    [
      [:show, 'show'],
      [:show?, 'show'],
      [:new?, 'new'],
      [:new, 'new'],
      [:edit?, 'edit'],
      [:edit, 'edit'],
      [:submit, 'submit'],
      [:submit?, 'submit'],
      [:attach, 'attach'],
      [Sipity::WorkflowAction.new(name: 'hello'), 'hello']
    ].each_with_index do |(original, expected), index|
      it "will convert #{original.inspect} to #{expected.inspect} (scenario ##{index})" do
        expect(PowerConverter.convert_to_sipity_action_name(original)).to eq(expected)
      end
    end

    it 'will raise an exception if it is not processible' do
      object = double('Bad Wolf')
      expect { PowerConverter.convert_to_sipity_action_name(object) }.to raise_error(PowerConverter::ConversionError)
    end

    it 'will leverage a short-circuit #to_processing_action_name' do
      object = double(to_sipity_action_name: 'bob')
      expect(PowerConverter.convert_to_sipity_action_name(object)).to eq('bob')
    end
  end
end
