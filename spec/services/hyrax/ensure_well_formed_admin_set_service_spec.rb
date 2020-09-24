# frozen_string_literal: true
RSpec.describe Hyrax::EnsureWellFormedAdminSetService do
  let(:default_id) { AdminSet::DEFAULT_ID }
  describe ".call" do
    subject { described_class.call(admin_set_id: given_admin_set_id) }
    context "with admin_set_id: nil" do
      let(:given_admin_set_id) { nil }
      it 'uses the default admin set and conditionally creates the associated permission template' do
        expect(AdminSet).to receive(:find_or_create_default_admin_set_id).and_return(default_id)
        expect(Hyrax::PermissionTemplate).to receive(:find_or_create_by!).with(source_id: default_id)
        expect(subject).to eq(default_id)
      end
    end
    context "with admin_set_id: <not nil>" do
      let(:given_admin_set_id) { 'admin_set/mine' }
      it 'uses the given admin_set_id and conditionally creates the associated permission template' do
        expect(AdminSet).not_to receive(:find_or_create_default_admin_set_id)
        expect(Hyrax::PermissionTemplate).to receive(:find_or_create_by!).with(source_id: given_admin_set_id)
        expect(subject).to eq(given_admin_set_id)
      end
    end
  end
end
