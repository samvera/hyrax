require 'spec_helper'

RSpec.describe CurationConcerns::Forms::WorkflowActionForm do
  # There is quite a bit of setup as I test this form.
  let(:sipity_entity) { Sipity::Entity.create!(proxy_for_global_id: '12', workflow: sipity_workflow, workflow_state_id: 2) }
  let(:sipity_workflow) { Sipity::Workflow.create!(name: 'testing') }
  let(:user) { FactoryGirl.create(:user) }
  let(:current_ability) { double(current_user: user) }
  let(:form) do
    described_class.new(current_ability: current_ability, work: sipity_entity, attributes: { name: 'an_action', comment: 'a_comment' })
  end

  let(:an_action) { double('AnAction', resulting_workflow_state_id: 3) }

  before do
    allow(PowerConverter).to receive(:convert_to_sipity_action).with('an_action', scope: sipity_entity.workflow).and_return(an_action)
  end

  context 'if the given user cannot perform the given action' do
    before { expect(CurationConcerns::Workflow::PermissionQuery).to receive(:authorized_for_processing?).and_return(false) }
    describe '#valid?' do
      subject { form.valid? }
      it { is_expected.to eq(false) }
    end
    describe '#save' do
      subject { form.save }
      it { is_expected.to eq(false) }
      it 'will not add a comment' do
        expect { form.save }.to_not change { Sipity::Comment.count }
      end
    end
  end
  context 'if the given user can perform the given action' do
    before { expect(CurationConcerns::Workflow::PermissionQuery).to receive(:authorized_for_processing?).and_return(true) }
    describe '#valid?' do
      subject { form.valid? }
      it { is_expected.to eq(true) }
    end
    describe '#save' do
      subject { form.save }
      it { is_expected.to eq(true) }
      it 'will update the state of the given work' do
        expect { form.save }.to change { sipity_entity.reload.workflow_state_id }.from(2).to(an_action.resulting_workflow_state_id)
      end
      it 'will create the given comment for the entity' do
        expect { form.save }.to change { Sipity::Comment.count }.by(1)
      end
    end
  end
end
