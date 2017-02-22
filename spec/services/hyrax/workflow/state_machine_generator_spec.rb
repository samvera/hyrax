require 'spec_helper'

module Hyrax
  RSpec.describe Workflow::StateMachineGenerator, :no_clean do
    let(:workflow) { create(:workflow, name: 'hello') }
    let(:action_name) { 'do_it' }
    before do
      class ConfirmSubmission
      end
    end
    after { Hyrax.send(:remove_const, :ConfirmSubmission) }
    it 'exposes .generate_from_schema as a convenience method' do
      expect_any_instance_of(described_class).to receive(:call)
      described_class.generate_from_schema(workflow: workflow, name: action_name, config: {})
    end

    let(:config) do
      {
        from_states: [
          { names: ["pending_student_completion"], roles: ['creating_user'] },
          { names: ["pending_advisor_completion"], roles: ['advising'] }
        ],
        transition_to: :under_review,
        notifications: [
          { notification_type: 'email', name: 'Hyrax::ConfirmSubmission', to: 'creating_user', cc: 'advising' }
        ]
      }
    end

    context '#call' do
      subject { described_class.new(workflow: workflow, action_name: action_name, config: config) }
      it 'will generate the various data entries (but only once)' do
        expect do
          subject.call
        end.to change { Sipity::Notification.count }
          .and change { Sipity::WorkflowAction.count }

        # It can be called repeatedly without updating things
        [:update_attribute, :update_attributes, :update_attributes!, :save, :save!, :update, :update!].each do |method_names|
          expect_any_instance_of(ActiveRecord::Base).not_to receive(method_names)
        end
        subject.call
      end
    end
  end
end
