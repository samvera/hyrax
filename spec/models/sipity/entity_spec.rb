require 'spec_helper'

module Sipity
  RSpec.describe Entity, type: :model do
    subject { described_class }
    its(:column_names) { is_expected.to include("proxy_for") }
    its(:column_names) { is_expected.to include("workflow_id") }
    its(:column_names) { is_expected.to include("workflow_state_id") }

    context 'an instance' do
      subject { described_class.new }
      it { is_expected.to delegate_method(:workflow_state_name).to(:workflow_state).as(:name) }
      it { is_expected.to delegate_method(:workflow_name).to(:workflow).as(:name) }
    end
  end
end
