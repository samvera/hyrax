# frozen_string_literal: true
RSpec.describe Hyrax::Admin::WorkflowRolePresenter do
  let(:presenter) { described_class.new(workflow_role) }
  let(:role) { Sipity::Role[:depositor] }
  let(:workflow) { create(:workflow) }
  let(:workflow_role) { Sipity::WorkflowRole.new(role: role, workflow: workflow) }

  describe '#label' do
    subject { presenter.label }

    it { is_expected.to be_a(String) }
  end
end
