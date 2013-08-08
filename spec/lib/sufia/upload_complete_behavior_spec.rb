require "spec_helper"
class UploadThing
  extend Sufia::FilesController::UploadCompleteBehavior
end

class UploadThingRedefine
  extend Sufia::FilesController::UploadCompleteBehavior
  def self.upload_complete_path(id)
    return "example.com"
  end

end

describe Sufia::FilesController::UploadCompleteBehavior do
  let (:test_id) {"123abc"}
  context "Not overridden" do
    it "respond with the batch edit path" do
      UploadThing.upload_complete_path(test_id).should == Sufia::Engine.routes.url_helpers.batch_edit_path(test_id)
    end
  end
  context "overriden path" do
    it "respond with the batch edit path" do
      UploadThingRedefine.upload_complete_path(test_id).should == "example.com"
    end
  end
end