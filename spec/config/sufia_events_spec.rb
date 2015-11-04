require 'spec_helper'
# Testing that these behaviors are configured (mainly they are triggered by CurationConcerns actors)
describe "sufia_events initialers sets CurationConcerns.config" do
  let(:file_set)  { double("FileSet", id: "6789") }
  let(:user)          { double("User", user_key: "an_id") }

  describe "after_create_content" do
    it "to queue a ContentDepositEventJob" do
      expect(ContentDepositEventJob).to receive(:new).with(file_set.id, user.user_key).and_return("the_job")
      expect(CurationConcerns.queue).to receive(:push).with("the_job")
      CurationConcerns.config.after_create_content.call(file_set, user)
    end
  end

  describe "after_revert_content" do
    let(:revision) { "revision1" }
    it "to queue a ContentDepositEventJob" do
      expect(ContentRestoredVersionEventJob).to receive(:new).with(file_set.id, user.user_key, revision).and_return("the_job")
      expect(CurationConcerns.queue).to receive(:push).with("the_job")
      CurationConcerns.config.after_revert_content.call(file_set, user, revision)
    end
  end

  describe "after_update_content" do
    it "to queue a ContentDepositEventJob" do
      expect(ContentNewVersionEventJob).to receive(:new).with(file_set.id, user.user_key).and_return("the_job")
      expect(CurationConcerns.queue).to receive(:push).with("the_job")
      CurationConcerns.config.after_update_content.call(file_set, user)
    end
  end

  describe "after_update_metadata" do
    it "to queue a ContentDepositEventJob" do
      expect(ContentUpdateEventJob).to receive(:new).with(file_set.id, user.user_key).and_return("the_job")
      expect(CurationConcerns.queue).to receive(:push).with("the_job")
      CurationConcerns.config.after_update_metadata.call(file_set, user)
    end
  end

  describe "after_destroy" do
    let(:id) { file_set.id }
    it "to queue a ContentDepositEventJob" do
      expect(ContentDeleteEventJob).to receive(:new).with(id, user.user_key).and_return("the_job")
      expect(CurationConcerns.queue).to receive(:push).with("the_job")
      CurationConcerns.config.after_destroy.call(id, user)
    end
  end
end
