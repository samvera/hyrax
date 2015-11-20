require 'spec_helper'

describe UploadSetUpdateJob do
  let(:user) { create(:user) }
  let(:upload_set) { UploadSet.create }

  let(:file)  { create(:file_set, user: user, upload_set: upload_set) }
  let(:file2) { create(:file_set, user: user, upload_set: upload_set) }
  let!(:work) do
    create(:work, user: user).tap do |work|
      work.ordered_members << file << file2
      work.save!
    end
  end

  before do
    allow(CurationConcerns.config.callback).to receive(:run)
    allow(CurationConcerns.config.callback).to receive(:set?)
      .with(:after_upload_set_update_success)
      .and_return(true)
    allow(CurationConcerns.config.callback).to receive(:set?)
      .with(:after_upload_set_update_failure)
      .and_return(true)
  end

  describe "#perform" do
    let(:title) { { file.id => ['File One'], file2.id => ['File Two'] } }
    let(:metadata) { { tag: [''] } }
    let(:visibility) { nil }

    subject { described_class.perform_now(user.user_key, upload_set.id, title, metadata, visibility) }

    it "updates file metadata" do
      expect(CurationConcerns.config.callback).to receive(:run).with(:after_upload_set_update_success, user, upload_set)
      expect(subject).to be true
      expect(file.reload.title).to eq ['File One']
      expect(file2.reload.title).to eq ['File Two']
    end

    context "when user does not have permission to edit all of the files" do
      before do
        expect_any_instance_of(User).to receive(:can?).with(:edit, file).and_return(true)
        expect_any_instance_of(User).to receive(:can?).with(:edit, file2).and_return(false)
        expect(CurationConcerns.config.callback).to receive(:run).with(:after_upload_set_update_failure, user, upload_set)
      end
      it { is_expected.to be false }
    end
  end
end
