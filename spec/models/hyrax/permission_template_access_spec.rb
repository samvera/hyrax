RSpec.describe Hyrax::PermissionTemplateAccess do
  let(:admin_set) { create(:admin_set, with_permission_template: true) }
  let(:permission_template_access) do
    create(:permission_template_access,
           :manage,
           permission_template: admin_set.permission_template,
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
      it 'aborts the destroy operation' do
        subject.destroy
        expect(subject).not_to be_destroyed
        expect(subject.errors.messages[:base]).to include 'The repository administrators group cannot be removed'
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
end
