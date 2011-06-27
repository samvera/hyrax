require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include JavascriptIncludesHelper
# include HydraHelper # This helper provides the Controller's javascript_includes method

describe JavascriptIncludesHelper do

  before(:each) do
    # Mock behavior of Controller's javascript_includes method
    @javascript_includes = []
    helper.stubs(:javascript_includes).returns(@javascript_includes)
  end
  
  describe "include_javascript_for" do
    it "should call custom helpers if they're defined" do
      helper.expects(:include_javascript_for_hydrangea_articles_edit)
      helper.include_javascript_for "hydrangea_articles", "edit" 
    end
    it "should rely on default_javascript_includes when given content type is not explicitly covered" do
      helper.expects(:include_default_javascript).with("edit")
      helper.include_javascript_for "my_type", "edit" 
    end
    it "should rely on default_javascript_includes when given action is not explicitly covered" do
      helper.expects(:include_default_javascript).with("delete")
      helper.include_javascript_for "catalog", "delete" 
    end
  end
  
  describe "include_default_javascript" do
    it "should do nothing if no includes are defined for the given action" do
      helper.expects(:javascript_includes).never
      helper.include_default_javascript("flip")
    end
    it "should use catalog includes for edit" do
      helper.expects(:include_javascript_for_catalog_edit)
      helper.include_default_javascript("edit")
    end
    it "should use catalog includes for show" do
      helper.expects(:include_javascript_for_catalog_show)
      helper.include_default_javascript("show")
    end
  end
  
end