RSpec.describe Hyrax::GrantEditJob do
  [true, false].each do |use_valkyrie|
    context "when use_valkyrie is #{use_valkyrie}" do
      let(:depositor) { create(:user) }
      let(:file_set) { create(:file_set) }

      it 'grants a user edit access to a FileSet' do
        described_class.perform_now(file_set.id, depositor.user_key, use_valkyrie: use_valkyrie)
        file_set.reload
        expect(file_set.edit_users).to include depositor.user_key
      end
    end
  end
end
