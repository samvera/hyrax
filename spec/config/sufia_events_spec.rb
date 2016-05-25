describe "sufia_events using CurationConcerns callbacks" do
  let(:curation_concern) { create(:work) }
  let(:file_set) { create(:file_set) }
  let(:user) { create(:user) }

  describe "after_create_concern" do
    it "queues a ContentDepositEventJob" do
      expect(ContentDepositEventJob).to receive(:perform_later).with(curation_concern, user)
      CurationConcerns.config.callback.run(:after_create_concern, curation_concern, user)
    end
  end

  describe "after_create_fileset" do
    it "queues a FileSetAttachedEventJob" do
      expect(FileSetAttachedEventJob).to receive(:perform_later).with(file_set, user)
      CurationConcerns.config.callback.run(:after_create_fileset, file_set, user)
    end
  end

  describe "after_revert_content" do
    let(:revision) { "revision1" }
    it "queues a ContentRestoredVersionEventJob" do
      expect(ContentRestoredVersionEventJob).to receive(:perform_later).with(file_set, user, revision)
      CurationConcerns.config.callback.run(:after_revert_content, file_set, user, revision)
    end
  end

  describe "after_update_content" do
    it "queues a ContentNewVersionEventJob" do
      expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)
      CurationConcerns.config.callback.run(:after_update_content, file_set, user)
    end
  end

  describe "after_update_metadata" do
    it "queues a ContentUpdateEventJob" do
      expect(ContentUpdateEventJob).to receive(:perform_later).with(curation_concern, user)
      CurationConcerns.config.callback.run(:after_update_metadata, curation_concern, user)
    end
  end

  describe "after_destroy" do
    let(:id) { curation_concern.id }
    it "queues a ContentDeleteEventJob" do
      expect(ContentDeleteEventJob).to receive(:perform_later).with(id, user)
      CurationConcerns.config.callback.run(:after_destroy, id, user)
    end
  end
end
