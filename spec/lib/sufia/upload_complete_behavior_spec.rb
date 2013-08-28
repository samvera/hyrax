require "spec_helper"
class UploadThing
  extend Sufia::FilesController::UploadCompleteBehavior
end

class UploadThingRedefine
  extend Sufia::FilesController::UploadCompleteBehavior
  def self.upload_complete_path(id)
    return "example.com"
  end

  def self.destroy_complete_path(id)
    return "destroy.com"
  end

end

describe Sufia::FilesController::UploadCompleteBehavior do
  let (:test_id) {"123abc"}
  context "Not overridden" do
    it "respond with the batch edit path" do
      UploadThing.upload_complete_path(test_id).should == Sufia::Engine.routes.url_helpers.batch_edit_path(test_id)
    end
    it "respond with the dashboard path" do
      UploadThing.destroy_complete_path({}).should ==   Sufia::Engine.routes.url_helpers.dashboard_index_path
    end
  end
  context "overriden path" do
    it "respond with the batch edit path" do
      UploadThingRedefine.upload_complete_path(test_id).should == "example.com"
    end
    it "respond with the batch edit path" do
      UploadThingRedefine.destroy_complete_path(test_id).should == "destroy.com"
    end
  end
end