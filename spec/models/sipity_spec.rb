RSpec.describe Sipity do
  describe '.WorkflowAction' do
    let(:workflow_id) { 1 }
    let(:action) { Sipity::WorkflowAction.new(id: 4, name: 'show', workflow_id: workflow_id) }

    context "with workflow_id and action's workflow_id matching" do
      it 'will return the object if it is a Sipity::WorkflowAction' do
        expect(described_class.WorkflowAction(action, workflow_id)).to eq(action)
      end

      it 'will return the object if it responds to #to_sipity_action' do
        object = double(to_sipity_action: action)
        expect(described_class.WorkflowAction(object, workflow_id)).to eq(action)
      end

      it 'will raise an error if it cannot convert the object' do
        object = double
        expect { described_class.WorkflowAction(object, workflow_id) }
          .to raise_error(Sipity::ConversionError)
      end

      it 'will use a found action based on the given string and workflow_id' do
        expect(Sipity::WorkflowAction).to receive(:find_by).and_return(action)
        expect(described_class.WorkflowAction(action.name, workflow_id)).to eq(action)
      end

      context "when the WorkflowAction can not be found" do
        it 'will raise an error' do
          expect(Sipity::WorkflowAction).to receive(:find_by).and_return(nil)
          expect { described_class.WorkflowAction(action.name, workflow_id) }
            .to raise_error(Sipity::ConversionError)
        end
      end
    end

    context "with mismatching workflow_id and action's workflow_id" do
      it "will fail an error if the scope's workflow_id is different than the actions" do
        expect { described_class.WorkflowAction(action, workflow_id + 1) }
          .to raise_error(Sipity::ConversionError)
      end
    end
  end
end
