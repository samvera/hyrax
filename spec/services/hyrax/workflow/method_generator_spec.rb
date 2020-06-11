# frozen_string_literal: true
RSpec.describe Hyrax::Workflow::MethodGenerator do
  describe ".call" do
    let(:workflow_action) { create(:workflow_action) }
    let(:method_list) { ['one', 'two'] }

    subject { described_class.call(action: workflow_action, list: method_list) }

    context "when there are no existing methods" do
      it "creates new methods" do
        subject
        expect(workflow_action.triggered_methods).to all(be_kind_of Sipity::Method)
        expect(workflow_action.triggered_methods.count).to eq 2
        expect(workflow_action.triggered_methods.map(&:weight)).to eq [0, 1]
      end
    end

    context "when there are now fewer methods " do
      before do
        workflow_action.triggered_methods.create!(service_name: 'four', weight: 0)
        workflow_action.triggered_methods.create!(service_name: 'five', weight: 1)
        workflow_action.triggered_methods.create!(service_name: 'six', weight: 2)
      end

      it "removes the old methods" do
        expect { subject }.to change { workflow_action.triggered_methods.count }.from(3).to(2)
        expect(workflow_action.triggered_methods.map(&:weight)).to eq [0, 1]
        expect(workflow_action.triggered_methods.map(&:service_name)).to eq ['one', 'two']
      end
    end

    context "when there are now more methods " do
      before do
        workflow_action.triggered_methods.create!(service_name: 'four', weight: 0)
      end
      it "adds the new methods" do
        expect { subject }.to change { workflow_action.triggered_methods.count }.from(1).to(2)
        expect(workflow_action.triggered_methods.map(&:weight)).to eq [0, 1]
        expect(workflow_action.triggered_methods.map(&:service_name)).to eq ['one', 'two']
      end
    end
  end
end
