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

    describe "when given object does not respond to #workflow_restriction?" do
      let(:object) { double }
      describe "when given ability can edit the given object" do
        before { expect(ability).to receive(:can?).with(:edit, object).and_return(true) }
        it { is_expected.to be_falsey }
      end
      describe "when given ability cannot edit the given object" do
        before { expect(ability).to receive(:can?).with(:edit, object).and_return(false) }
        context "and the object is suppressed" do
          let(:object) { double(suppressed?: true) }
          it { is_expected.to be_truthy }
        end
        context "and the object is NOT suppressed" do
          let(:object) { double(suppressed?: false) }
          it { is_expected.to be_falsey }
        end

        context "and the object does not respond to #suppressed?" do
          let(:object) { double }
          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
