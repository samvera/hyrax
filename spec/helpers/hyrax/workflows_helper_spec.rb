# frozen_string_literal: true
RSpec.describe Hyrax::WorkflowsHelper do
  describe "#workflow_restriction?" do
    let(:ability) { double }
    before { allow(controller).to receive(:current_ability).and_return(ability) }
    subject { helper.workflow_restriction?(object) }
    describe "when given object responds to #workflow_restriction?" do
      let(:object) { double(workflow_restriction?: returning_value) }
      context "with true" do
        let(:returning_value) { true }
        it { is_expected.to be_truthy }
      end
      context "with false" do
        let(:returning_value) { false }
        it { is_expected.to be_falsey }
      end
    end
  end
end
