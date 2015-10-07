require 'spec_helper'

describe UploadSetUpdateJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:upload_set) { UploadSet.create }

  let!(:file)  { create(:file_set, user: user, upload_set: upload_set) }
  let!(:file2) { create(:file_set, user: user, upload_set: upload_set) }

  describe "#perform" do
    let(:title) { { file.id => ['File One'], file2.id => ['File Two'] } }
    let(:metadata) do
      { read_groups_string: '', read_users_string: 'archivist1, archivist2',
        tag: [''] }.with_indifferent_access
    end

    let(:visibility) { nil }

    let(:job) { described_class.perform_now(user.user_key, upload_set.id, title, metadata, visibility) }

    it "updates file metadata" do
      expect(job).to eq true
      expect(file.reload.title).to eq ['File One']
    end

    context "when user does not have permission to edit all of the files" do
      before do
        expect_any_instance_of(User).to receive(:can?).with(:edit, file).and_return(true)
        expect_any_instance_of(User).to receive(:can?).with(:edit, file2).and_return(false)
      end
      it "does not run" do
        expect(job).to eq false
      end
    end
  end
end
