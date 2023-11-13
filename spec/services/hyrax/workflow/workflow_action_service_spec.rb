# frozen_string_literal: true
require "spec_helper"

RSpec.describe Hyrax::Workflow::WorkflowActionService, :clean_repo do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

  let(:sipity_entity) do
    FactoryBot
      .create(:sipity_entity,
              proxy_for_global_id: work.to_global_id.to_s,
              workflow_state_id: 2)
  end

  let(:an_action) do
    instance_double(Sipity::WorkflowAction,
                    resulting_workflow_state_id: 3,
                    notifiable_contexts: [],
                    triggered_methods: Sipity::Method.none)
  end

  describe '.run' do
    subject do
      described_class.run(
        subject: ::Hyrax::WorkflowActionInfo.new(work, user),
        action: an_action,
        comment: 'a_comment'
      )
    end

    context 'the action has a resulting_workflow_state_id' do
      it 'will update the state of the given work and index it' do
        expect(work).to receive(:update_index)

        expect(sipity_entity.reload.workflow_state_id)
          .to change
          .from(2)
          .to(an_action.resulting_workflow_state_id)
      end
    end

    context 'and the action does not have a resulting_workflow_state_id' do
      let(:an_action) do
        instance_double(Sipity::WorkflowAction,
                        resulting_workflow_state_id: nil,
                        notifiable_contexts: [],
                        triggered_methods: Sipity::Method.none)
      end

      it 'will not update the state of the given work' do
        expect(sipity_entity.reload.workflow_state_id).not_to change
      end
    end

    it 'will create the given comment for the entity' do
      expect(Sipity::Comment.count).to change.by(1)
    end

    it 'will send the #deliver_on_action_taken message to Hyrax::Workflow::NotificationService' do
      expect(Hyrax::Workflow::NotificationService)
        .to receive(:deliver_on_action_taken)
        .with(entity: sipity_entity,
              comment: kind_of(Sipity::Comment),
              action: an_action,
              user: user)
    end

    it 'will send the #handle_action_taken message to Hyrax::Workflow::ActionTakenService' do
      expect(Hyrax::Workflow::ActionTakenService)
        .to receive(:handle_action_taken)
        .with(target: work,
              comment: kind_of(Sipity::Comment),
              action: an_action,
              user: user)
    end
  end
end
