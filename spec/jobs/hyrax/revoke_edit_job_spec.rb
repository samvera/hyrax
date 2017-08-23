RSpec.describe Hyrax::RevokeEditJob do
  let(:depositor) { create(:user) }
  let(:file_set) { build(:file_set, user: depositor) }

  it 'revokes edit access from a FileSet' do
    expect(FileSet).to receive(:find).with(file_set.id).and_return(file_set)
    expect(file_set).to receive(:edit_users=).with([])
    expect(file_set).to receive(:save!)
    described_class.perform_now(file_set.id, depositor.user_key)
  end
end
