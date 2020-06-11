# frozen_string_literal: true
RSpec.describe Hyrax::PermissionTemplateAccess do
  let(:permission_template) { create(:permission_template) }
  let(:permission_template_access) do
    create(:permission_template_access,
           :manage,
           permission_template: permission_template,
           agent_type: agent_type,
           agent_id: agent_id)
  end

  subject { permission_template_access }

  context 'with the admin users group' do
    let(:agent_type) { 'group' }
    let(:agent_id) { 'admin' }

    describe '#label' do
      it 'returns the repo admins label' do
        expect(subject.label).to eq 'Repository Administrators'
      end
    end
    describe '#admin_group?' do
      it 'returns true' do
        expect(subject).to be_admin_group
      end
    end
    describe '#destroy' do
      it 'destroys the permission template access record' do
        subject.destroy
        expect(subject).to be_destroyed
      end
    end
  end

  context 'with an agent that is not the admin users group' do
    let(:agent_type) { 'user' }
    let(:agent_id) { 'foobar' }

    describe '#label' do
      it 'returns the repo admins label' do
        expect(subject.label).to eq agent_id
      end
    end
    describe '#admin_group?' do
      it 'returns true' do
        expect(subject).not_to be_admin_group
      end
    end
    describe '#destroy' do
      it 'carries out the destroy operation' do
        subject.destroy
        expect(subject).to be_destroyed
        expect(subject.errors).to be_empty
      end
    end
  end

  context 'with a user that is an admin set viewer' do
    let(:agent_type) { 'user' }
    let(:agent_id) { 'foobar' }

    let(:permission_template_access) do
      create(:permission_template_access,
             :view,
             permission_template: permission_template,
             agent_type: agent_type,
             agent_id: agent_id)
    end

    subject { permission_template_access }

    describe '#label' do
      it 'returns the user label' do
        expect(subject.label).to eq agent_id
      end
    end
    describe '#admin_group?' do
      it 'returns true' do
        expect(subject).not_to be_admin_group
      end
    end
    describe '#destroy' do
      it 'carries out the destroy operation' do
        subject.destroy
        expect(subject).to be_destroyed
        expect(subject.errors).to be_empty
      end
    end
  end

  context 'with a user that is an admin set depositor' do
    let(:agent_type) { 'user' }
    let(:agent_id) { 'foobar' }

    let(:permission_template_access) do
      create(:permission_template_access,
             :deposit,
             permission_template: permission_template,
             agent_type: agent_type,
             agent_id: agent_id)
    end

    subject { permission_template_access }

    describe '#label' do
      it 'returns the user label' do
        expect(subject.label).to eq agent_id
      end
    end
    describe '#admin_group?' do
      it 'returns true' do
        expect(subject).not_to be_admin_group
      end
    end
    describe '#destroy' do
      it 'carries out the destroy operation' do
        subject.destroy
        expect(subject).to be_destroyed
        expect(subject.errors).to be_empty
      end
    end
  end

  context 'with a user that is an admin set manager' do
    let(:agent_type) { 'user' }
    let(:agent_id) { 'foobar' }

    let(:permission_template_access) do
      create(:permission_template_access,
             :manage,
             permission_template: permission_template,
             agent_type: agent_type,
             agent_id: agent_id)
    end

    subject { permission_template_access }

    describe '#label' do
      it 'returns the user label' do
        expect(subject.label).to eq agent_id
      end
    end
    describe '#admin_group?' do
      it 'returns true' do
        expect(subject).not_to be_admin_group
      end
    end
    describe '#destroy' do
      it 'carries out the destroy operation' do
        subject.destroy
        expect(subject).to be_destroyed
        expect(subject.errors).to be_empty
      end
    end
  end

  describe "duplicate records" do
    let(:permission_template) { create(:permission_template) }
    let(:agent_type) { 'user' }
    let(:agent_id) { 'foobar' }

    before do
      create(:permission_template_access,
             :view,
             permission_template: permission_template,
             agent_type: agent_type,
             agent_id: agent_id)
    end

    subject do
      build(:permission_template_access,
            :view,
            permission_template: permission_template,
            agent_type: agent_type,
            agent_id: agent_id)
    end

    it { is_expected.not_to be_valid }
  end
end
