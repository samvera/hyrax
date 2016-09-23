require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::ActionTakenService do
  context 'class methods' do
    subject { described_class }
    it { is_expected.to respond_to(:handle_action_taken) }
  end
end
