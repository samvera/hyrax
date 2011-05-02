require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )

require "hydra"

class FakeAssetsController
  include MediaShelf::ActiveFedoraHelper
end

def helper
  @fake_controller
end

describe MediaShelf::ActiveFedoraHelper do

  before(:all) do
    @fake_controller = FakeAssetsController.new
  end
  
  describe "retrieve_af_model" do
    it "should return a Model class if the named model has been defined" do
      result = helper.retrieve_af_model("file_asset")
      result.should == FileAsset
      result.superclass.should == ActiveFedora::Base
      result.included_modules.should include(ActiveFedora::Model) 
    end
    
    it "should accept camel cased OR underscored model name" do
       result = helper.retrieve_af_model("generic_content")
       result.should == GenericContent
        
       result = helper.retrieve_af_model("GenericContent")
       result.should == GenericContent
    
    end
    
    it "should return false if the name is not a real class" do
       result = helper.retrieve_af_model("foo_foo_class_class")
       result.should be_false
    end
    
  end

  describe "load_af_instance_from_solr" do
    it "should return an ActiveFedora object given a valid solr doc same as loading from Fedora" do
      pid = "hydrangea:fixture_mods_article1"
      result = ActiveFedora::Base.find_by_solr(pid)
      solr_doc = result.hits.first 
      solr_af_obj = helper.load_af_instance_from_solr(solr_doc)
      fed_af_obj = ActiveFedora::Base.load_instance(pid)
      #check both inbound and outbound match
      fed_af_obj.outbound_relationships.should == solr_af_obj.outbound_relationships
      fed_af_obj.inbound_relationships.should == solr_af_obj.inbound_relationships
    end
  end
  
end
