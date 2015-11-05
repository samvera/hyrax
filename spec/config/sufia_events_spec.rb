require 'spec_helper'
# Testing that these behaviors are configured (mainly they are triggered by CurationConcerns actors)
describe "sufia_events initialers sets CurationConcerns.config" do
  # TODO: mock file_set so it doesn't have to be created
  let(:file_set)  { create(:file_set) }
  let(:user)      { create(:user) }

  describe "after_create_content" do
    it "to queue a ContentDepositEventJob" do
      expect(ContentDepositEventJob).to receive(:perform_later).with(file_set.id, user.user_key).once
      CurationConcerns.config.callback.run(:after_create_content, file_set, user)
    end
  end

  describe "after_revert_content" do
    let(:revision) { "revision1" }
    it "to queue a ContentDepositEventJob" do
      expect(ContentRestoredVersionEventJob).to receive(:perform_later).with(file_set.id, user.user_key, revision).once
      CurationConcerns.config.callback.run(:after_revert_content, file_set, user, revision)
    end
  end

  describe "after_update_content" do
    it "to queue a ContentDepositEventJob" do
      expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set.id, user.user_key).once
      CurationConcerns.config.callback.run(:after_update_content, file_set, user)
    end
  end

  describe "after_update_metadata" do
    it "to queue a ContentDepositEventJob" do
      expect(ContentUpdateEventJob).to receive(:perform_later).with(file_set.id, user.user_key).once
      CurationConcerns.config.callback.run(:after_update_metadata, file_set, user)
    end
  end

  describe "after_destroy" do
    let(:id) { file_set.id }
    it "to queue a ContentDepositEventJob" do
      expect(ContentDeleteEventJob).to receive(:perform_later).with(id, user.user_key).once
      CurationConcerns.config.callback.run(:after_destroy, id, user)
    end
  end
end
