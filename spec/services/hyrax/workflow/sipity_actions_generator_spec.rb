# frozen_string_literal: true
module Hyrax
  module Workflow
    RSpec.describe SipityActionsGenerator do
      let(:workflow) { Sipity::Workflow.new(name: 'Hello') }
      let(:actions_configuration) do
        [
          {
            name: "start_a_submission", transition_to: "new", emails: [
              { name: "confirmation_of_ulra_submission_started", to: "creating_user" }
            ]
          }, {
            name: "submit", transition_to: "done", from_states: [{ names: ["new"], roles: ["submitting"] }]
          }
        ]
      end

      let(:new_actions_configuration) do
        [
          {
            name: "submit", transition_to: "done", from_states: [{ names: ["new"], roles: ["submitting"] }]
          }
        ]
      end

      context '.call' do
        it 'is a convenience method' do
          expect_any_instance_of(described_class).to receive(:call)
          described_class.call(workflow: workflow, actions_configuration: actions_configuration)
        end
      end

      subject { described_class.new(workflow: workflow, actions_configuration: actions_configuration) }

      it 'parses the actions_configuration and calls the underlying DataGenerators::StateMachineGenerator' do
        allow_any_instance_of(StateMachineGenerator).to receive(:call)
        subject.call
      end
    end
  end
end
