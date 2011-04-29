require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )


# See cucumber tests (ie. /features/edit_document.feature) for more tests, including ones that test the edit method & view
# You can run the cucumber tests with 
#
# cucumber --tags @edit
# or
# rake cucumber

describe Hydra::RepositoryController do
  
  describe "load_document_from_params" do
    it "should choose which model to use based on submitted params" do
      mock_model_class = mock("model class")
      mock_model_class.expects(:find).with("object id")
      helper.params = {:content_type => "preferred model", :id => "object id"}
      helper.expects(:retrieve_af_model).with("preferred model").returns(mock_model_class)
      helper.load_document_from_params
    end
  end
  
  describe "format_pid" do
    it "convert pids into XHTML safe strings" do 
     pid = helper.format_pid("hydra:123")
     pid.should match(/hydra_123/)   
    end 
  end
  
  
  
end