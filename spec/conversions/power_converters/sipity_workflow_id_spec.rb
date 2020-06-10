# frozen_string_literal: true
require "spec_helper"

RSpec.describe 'PowerConverter' do
  [
    [Sipity::Workflow.new(id: 12), 12],
    ["11", 11],
    [2, 2],
    [Sipity::Entity.new(workflow_id: 37), 37]
  ].each_with_index do |(to_convert, expected), index|
    it "will convert #{to_convert.inspect} to #{expected} (Scenario ##{index}" do
      expect(PowerConverter.convert_to_sipity_workflow_id(to_convert)).to eq(expected)
    end
  end

  it "will convert a processing entity to a strategy" do
    to_convert = double(to_sipity_entity: double(workflow_id: 1))
    expect(PowerConverter.convert_to_sipity_workflow_id(to_convert)).to eq(1)
  end

  it "will fail if the to_processing_entity fails a processing entity to a strategy" do
    to_convert = double(to_processing_entity: double)
    expect { PowerConverter.convert_to_sipity_workflow_id(to_convert) }.to raise_error(PowerConverter::ConversionError)
  end

  it 'will raise an exception if it cannot convert' do
    expect { PowerConverter.convert_to_sipity_workflow_id(double) }.to raise_error(PowerConverter::ConversionError)
  end
end
