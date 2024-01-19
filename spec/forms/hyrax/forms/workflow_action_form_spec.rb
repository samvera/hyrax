# frozen_string_literal: true
RSpec.describe Hyrax::Forms::WorkflowActionForm do
  subject(:form) do
    described_class.new(current_ability: Ability.new(user),
                        work: work,
                        attributes: { name: 'an_action', comment: 'a_comment' })
  end

  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

  let(:sipity_entity) do
    FactoryBot
      .create(:sipity_entity,
              proxy_for_global_id: Hyrax::GlobalID(work).to_s,
              workflow_state_id: 2)
  end

  let(:an_action) do
    instance_double(Sipity::WorkflowAction,
                    resulting_workflow_state_id: 3,
                    notifiable_contexts: [],
                    triggered_methods: Sipity::Method.none)
  end

  context 'if the given user cannot perform the given action' do
    before do
      allow(described_class)
        .to receive(:workflow_action_for)
        .with('an_action', scope: sipity_entity.workflow)
        .and_return(an_action)

      expect(Hyrax::Workflow::PermissionQuery)
        .to receive(:authorized_for_processing?)
        .and_return(false)
    end

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#save' do
      it 'gives false for failure' do
        expect(form.save).to be false
      end

      it 'will not add a comment' do
        expect { form.save }.not_to change { Sipity::Comment.count }
      end

      it 'will not send the #deliver_on_action_taken message to Hyrax::Workflow::NotificationService' do
        expect(Hyrax::Workflow::NotificationService)
          .not_to receive(:deliver_on_action_taken)

        form.save
      end

      it 'will not send the #handle_action_taken message to Hyrax::Workflow::ActionTakenService' do
        expect(Hyrax::Workflow::ActionTakenService)
          .not_to receive(:handle_action_taken)

        form.save
      end
    end
  end

  context 'if the given user can perform the given action' do
    before do
      allow(described_class).to receive(:workflow_action_for).with('an_action', scope: sipity_entity.workflow).and_return(an_action)

      expect(Hyrax::Workflow::PermissionQuery)
        .to receive(:authorized_for_processing?)
        .and_return(true)
    end

    describe '#valid?' do
      it { is_expected.to be_valid }
    end

    describe '#save' do
      before do
        allow(work).to receive(:update_index)
      end

      it 'gives true for success' do
        expect(form.save).to be true
      end

      context 'and the action has a resulting_workflow_state_id' do
        it 'will update the state of the given work and index it' do
          expect(work).to receive(:update_index)

          expect { form.save }
            .to change { sipity_entity.reload.workflow_state_id }
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
          expect { form.save }
            .not_to change { sipity_entity.reload.workflow_state_id }
        end
      end

      it 'will create the given comment for the entity' do
        expect { form.save }
          .to change { Sipity::Comment.count }
          .by(1)
      end

      it 'will send the #deliver_on_action_taken message to Hyrax::Workflow::NotificationService' do
        expect(Hyrax::Workflow::NotificationService)
          .to receive(:deliver_on_action_taken)
          .with(entity: sipity_entity,
                comment: kind_of(Sipity::Comment),
                action: an_action,
                user: user)

        form.save
      end

      it 'will send the #handle_action_taken message to Hyrax::Workflow::ActionTakenService' do
        expect(Hyrax::Workflow::ActionTakenService)
          .to receive(:handle_action_taken)
          .with(target: work,
                comment: kind_of(Sipity::Comment),
                action: an_action,
                user: user)

        form.save
      end
    end
  end

  context 'when no option is selected upon initialization' do
    before { sipity_entity } # prebuild the entity

    subject(:form) do
      described_class.new(current_ability: Ability.new(user),
                          work: work,
                          attributes: { comment: '' })
    end

    it 'will be invalid' do
      expect(form).not_to be_valid
    end
  end
end
