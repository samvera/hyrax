# frozen_string_literal: true
RSpec.describe Hyrax::RevokeEditJob do
  let(:depositor) { create(:user) }

  context "when use_valkyrie is false", :active_fedora do
    let(:file_set) { create(:file_set) }

    it "revokes a user's edit access to a FileSet" do
      described_class.perform_now(file_set.id, depositor.user_key, use_valkyrie: false)
      file_set.reload
      expect(file_set.edit_users).not_to include depositor.user_key
    end
  end

  context 'when use_valkyire is true' do
    let(:file_set) { valkyrie_create(:hyrax_file_set) }

    it "revokes a user's edit access to a FileSet" do
      described_class.perform_now(file_set.id.to_s, depositor.user_key, use_valkyrie: true)
      reloaded_file_set = Hyrax.query_service.find_by(id: file_set.id)
      expect(reloaded_file_set.edit_users).not_to include depositor.user_key
    end
  end
end
