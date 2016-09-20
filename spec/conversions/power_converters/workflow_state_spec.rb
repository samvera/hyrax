require 'spec_helper'
require "#{CurationConcerns::Engine.root}/app/conversions/power_converters/workflow_state"

RSpec.describe 'PowerConverter', no_clean: true do
  context 'workflow_state' do
    let(:workflow_state) { Sipity::WorkflowState.new(id: 1, name: 'hello') }
    let(:workflow) { Sipity::Workflow.new(id: 2, name: 'workflow') }
    it 'will convert a Sipity::WorkflowState' do
      expect(PowerConverter.convert(workflow_state, to: :workflow_state)).to eq(workflow_state)
    end

    it 'will convert a string based on scope' do
      Sipity::WorkflowState.create!(workflow_id: workflow.id, name: 'hello')
      PowerConverter.convert('hello', scope: workflow, to: :workflow_state)
    end

    it 'will attempt convert a string based on scope' do
      expect { PowerConverter.convert('missing', scope: workflow, to: :workflow_state) }
        .to raise_error(PowerConverter::ConversionError)
    end
  end
end
