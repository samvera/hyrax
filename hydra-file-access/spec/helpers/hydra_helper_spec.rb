require 'spec_helper'


describe HydraHelper do
  
  describe "submit_name" do
    it "should return 'Save' when the scripts session variable is set" do
      helper.stub(:session => {:scripts=>true})
      helper.submit_name.should == "Save"
    end
    it "should return 'Continue' when the new_asset param is set" do
      helper.stub(:params => {:new_asset=>true})
      helper.submit_name.should == "Continue"
    end
    it "should return 'Save and Continue' if all else fails" do
      helper.stub(:params => {})
      helper.submit_name.should == "Save and Continue"
    end
  end
  
end
