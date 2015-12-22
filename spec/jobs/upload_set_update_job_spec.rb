require 'spec_helper'

describe UploadSetUpdateJob do
  let(:user) { create(:user) }
  let(:upload_set) { UploadSet.create }

  let(:work)  { create(:work, user: user, upload_set: upload_set) }
  let(:work2) { create(:work, user: user, upload_set: upload_set) }

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
    before do
      allow(UploadSet).to receive(:acquire_lock_for).and_yield if $in_travis
    end

    let(:title) { { work.id => ['File One'], work2.id => ['File Two'] } }
    let(:metadata) { { tag: [''] } }
    let(:visibility) { nil }

    subject { described_class.perform_now(user.user_key, upload_set.id, title, metadata, visibility) }

    it "updates work metadata" do
      expect(CurationConcerns.config.callback).to receive(:run).with(:after_upload_set_update_success, user, upload_set)
      subject
      expect(work.reload.title).to eq ['File One']
      expect(work2.reload.title).to eq ['File Two']
    end

    context "when user does not have permission to edit all of the works" do
      it "sends the failure message" do
        expect_any_instance_of(User).to receive(:can?).with(:edit, work).and_return(true)
        expect_any_instance_of(User).to receive(:can?).with(:edit, work2).and_return(false)
        expect(CurationConcerns.config.callback).to receive(:run).with(:after_upload_set_update_failure, user, upload_set)
        subject
      end
    end
  end
end
