require 'spec_helper'

RSpec.describe CurationConcerns::Forms::WorkflowActionForm do
  let(:sipity_entity) { Sipity::Entity.create!(proxy_for_global_id: '12', workflow_id: 1, workflow_state_id: 2) }
  let(:user) { FactoryGirl.create(:user) }
  let(:current_ability) { double(current_user: user) }
  let(:form) do
    described_class.new(current_ability: current_ability, work: sipity_entity, workflow_action: { name: 'an_action', comment: 'a_comment' })
  end

  it 'exposes .save as part of the public API' do
    expect_any_instance_of(described_class).to receive(:save)
    described_class.save(
      current_ability: current_ability, work: sipity_entity, workflow_action: { name: 'an_action', comment: 'a_comment' }
    )
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
      xit 'will update the state of the given work'
      it 'will create the given comment for the entity' do
        expect { form.save }.to change { Sipity::Comment.count }.by(1)
      end
    end
  end
end
