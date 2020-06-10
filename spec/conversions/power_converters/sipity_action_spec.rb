# frozen_string_literal: true
require "spec_helper"

RSpec.describe 'PowerConverter' do
  let(:workflow_id) { 1 }
  let(:action) { Sipity::WorkflowAction.new(id: 4, name: 'show', workflow_id: workflow_id) }

  context "with workflow_id and action's workflow_id matching" do
    it 'will return the object if it is a Sipity::WorkflowAction' do
      expect(PowerConverter.convert(action, to: :sipity_action, scope: workflow_id)).to eq(action)
    end

    it 'will return the object if it responds to #to_sipity_action' do
      object = double(to_sipity_action: action)
      expect(PowerConverter.convert(object, to: :sipity_action, scope: workflow_id)).to eq(action)
    end

    it 'will raise an error if it cannot convert the object' do
      object = double
      expect { PowerConverter.convert(object, to: :sipity_action, scope: workflow_id) }
        .to raise_error(PowerConverter::ConversionError)
    end

    it 'will use a found action based on the given string and workflow_id' do
      expect(Sipity::WorkflowAction).to receive(:find_by).and_return(action)
      expect(PowerConverter.convert(action.name, to: :sipity_action, scope: workflow_id)).to eq(action)
    end

    context "when the WorkflowAction can not be found" do
      it 'will raise an error' do
        expect(Sipity::WorkflowAction).to receive(:find_by).and_return(nil)
        expect { PowerConverter.convert(action.name, to: :sipity_action, scope: workflow_id) }
          .to raise_error(PowerConverter::ConversionError)
      end
    end
  end

  context "with mismatching workflow_id and action's workflow_id" do
    it "will fail an error if the scope's workflow_id is different than the actions" do
      expect { PowerConverter.convert(action, to: :sipity_action, scope: workflow_id + 1) }
        .to raise_error(PowerConverter::ConversionError)
    end
  end
end
