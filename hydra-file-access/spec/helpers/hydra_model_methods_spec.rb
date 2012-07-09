require 'spec_helper'

describe Hydra::ModelMethods do
  
  
  describe "set_title_and_label" do
    before(:each) do
      dm = mock("descMetadata")
      helper.stub(:datastreams).and_return("descMetadata"=>dm)
    end
    it "should set the title and the label" do
      helper.should_receive(:set_title)
      helper.stub(:label).and_return(nil)
      helper.should_receive(:label=).with("My title")
      helper.set_title_and_label("My title")
    end
    it "should skip updating if the label is set already" do
      helper.should_receive(:set_title).never
      helper.should_receive(:label=).never
      helper.stub(:label).and_return("pre existing label")
      helper.set_title_and_label("My title", :only_if_blank=>true)
    end
  end
  
  describe "set_title" do
    it "should set the title if the descMetadata is a NokogiriDatastream that responds to :title term" do
      obj = ActiveFedora::Base.new
      dm = Hydra::Datastream::ModsArticle.new(obj.inner_object, nil)
      dm.stub(:content).and_return('')
      helper.stub(:datastreams).and_return("descMetadata"=>dm)
      helper.set_title("My title")
      dm.term_values(:title).should == ["My title"]
    end
    it "should set the title if the descMetadata is a MetadataDatastream with a title field defined" do
      obj = ActiveFedora::Base.new
      dm = ActiveFedora::QualifiedDublinCoreDatastream.new(obj.inner_object, nil)
      dm.stub(:content).and_return('')
      #dm = ActiveFedora::QualifiedDublinCoreDatastream.new  nil, nil 
      helper.stub(:datastreams).and_return("descMetadata"=>dm)
      helper.set_title("My title")
      dm.title.should == ["My title"]
    end
  end
  
  describe "set_collection_type" do
    it "should set the collection metadata field" do
      prop_ds = mock("properties ds")
      prop_ds.should_receive(:respond_to?).with(:collection_values).and_return(true)
      prop_ds.should_receive(:collection_values=).with("mods_asset")

      helper.stub(:datastreams).and_return({"properties"=>prop_ds})
      helper.set_collection_type("mods_asset")
    end
  end

  describe "#destroyable_child_assets" do
    it "should return an array of file assets available for deletion" do
      ma = ModsAsset.load_instance_from_solr("hydrangea:fixture_mods_article1")
      deletable_assets = ma.destroyable_child_assets
      deletable_assets.should be_a_kind_of Array
      deletable_assets.length.should >= 1
      deletable_assets.select {|a| a.pid == "hydrangea:fixture_uploaded_svg1"}[0].pid.should == "hydrangea:fixture_uploaded_svg1"
    end
    it "should return an empty array if there are now file assets" do
      ma = ModsAsset.load_instance_from_solr("hydrangea:fixture_mods_article2")
      deletable_assets = ma.destroyable_child_assets
      deletable_assets.should be_a_kind_of Array
      deletable_assets.should be_empty
    end
  end

  describe "#destroy_child_assets" do
    it "should destroy any child assets and return an array listing the child assets" do
      ma = ModsAsset.load_instance_from_solr("hydrangea:fixture_mods_article1")
      file_asset = mock("file object")
      file_asset.should_receive(:pid).and_return("hydrangea:fixture_uploaded_svg1")
      file_asset.should_receive(:delete).and_return(true)
      ma.stub(:destroyable_child_assets).and_return([file_asset])
      ma.destroy_child_assets.should == ["hydrangea:fixture_uploaded_svg1"]
    end
    it "should do nothing and return an empty array for an object with no child assets" do
      ma = ModsAsset.load_instance_from_solr("hydrangea:fixture_mods_article2")
      ma.destroy_child_assets.should == []
    end
  end


end
