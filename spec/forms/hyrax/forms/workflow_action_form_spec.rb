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
              proxy_for_global_id: work.to_global_id.to_s,
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
    end
  end

  context 'if the given user can perform the given action' do
    before do
      allow(described_class)
        .to receive(:workflow_action_for)
        .with('an_action', scope: sipity_entity.workflow)
        .and_return(an_action)

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

      it 'enqueues WorkflowActionJob' do
        expect(WorkflowActionJob).to(
          receive(:perform_later).with(
            comment: 'a_comment',
            name: 'an_action',
            user: user,
            work_id: work.id.to_s,
            workflow: sipity_entity.workflow
          )
        )
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
