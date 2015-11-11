require "spec_helper"
class UploadThing
  extend Sufia::FilesController::UploadCompleteBehavior
end

class UploadThingRedefine
  extend Sufia::FilesController::UploadCompleteBehavior
  def self.upload_complete_path(_id)
    "example.com"
  end

  def self.destroy_complete_path(_id)
    "destroy.com"
  end
end

describe Sufia::FilesController::UploadCompleteBehavior do
  let(:test_id) { "123abc" }
  context "Not overridden" do
    it "respond with the batch edit path" do
      expect(UploadThing.upload_complete_path(test_id)).to eq(Rails.application.routes.url_helpers.edit_upload_set_path(test_id))
    end
    it "respond with the dashboard path" do
      expect(UploadThing.destroy_complete_path({})).to eq(Sufia::Engine.routes.url_helpers.dashboard_files_path)
    end
  end
  context "overriden path" do
    it "respond with the batch edit path" do
      expect(UploadThingRedefine.upload_complete_path(test_id)).to eq("example.com")
    end
    it "respond with the batch edit path" do
      expect(UploadThingRedefine.destroy_complete_path(test_id)).to eq("destroy.com")
    end
  end
end
