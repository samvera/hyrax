require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::NotificationService do
  context 'class methods' do
    subject { described_class }
    it { is_expected.to respond_to(:deliver_on_action_taken) }
  end
end
