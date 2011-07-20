require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

class DummyFileAsset < ActiveFedora::Base
  def initialize(attr={})
    super(attr)
    add_relationship(:has_model, "info:fedora/afmodel:FileAsset")
  end
end

describe FileAsset do
  before(:each) do
    @file_asset = FileAsset.new
    @image_asset = ImageAsset.new
    @audio_asset = AudioAsset.new
    @video_asset = VideoAsset.new
    @asset1 = ActiveFedora::Base.new
    @asset2 = ActiveFedora::Base.new
    @asset3 = ActiveFedora::Base.new
    @dummy_file_asset = DummyFileAsset.new
    @asset1.save
    @asset2.save
    @asset3.save
    @image_asset.save
    @audio_asset.save
    @video_asset.save
    @dummy_file_asset.save
  end

  after(:each) do
    begin
    @file_asset.delete
    rescue
    end
    begin
    @asset1.delete
    rescue
    end
    begin
    @asset2.delete
    rescue
    end
    begin
    @asset3.delete
    rescue
    end
    begin
    @image_asset.delete
    rescue
    end
    begin
    @audio_asset.delete
    rescue
    end
    begin
    @video_asset.delete
    rescue
    end
    begin
    @dummy_file_asset.delete
    rescue
    end
  end

  describe ".containers" do    
    it "should return asset container objects via either inbound has_collection_member, inbound has_part, or outbound is_part_of relationships" do
      #test all possible combinations...
      #none
      @file_asset.containers(:response_format=>:id_array).should == []
      #is_part_of
      @file_asset.part_of_append(@asset1)
      @file_asset.containers(:response_format=>:id_array).should == [@asset1.pid]
      #has_part + is_part_of
      @asset2.parts_append(@file_asset)
      @asset2.save
      @file_asset.containers(:response_format=>:id_array).should == [@asset2.pid,@asset1.pid]
      #has_part
      @file_asset.part_of_remove(@asset1)
      @file_asset.containers(:response_format=>:id_array).should == [@asset2.pid]      
      #has_collection_member
      @asset2.parts_remove(@file_asset)
      @asset2.save
      @asset3.collection_members_append(@file_asset)
      @asset3.save
      @file_asset.containers(:response_format=>:id_array).should == [@asset3.pid]
      #is_part_of + has_collection_member
      @file_asset.part_of_append(@asset1)
      @file_asset.containers(:response_format=>:id_array).should == [@asset3.pid,@asset1.pid]
      #has_part + has_collection_member      
      @file_asset.part_of_remove(@asset1)
      @asset2.parts_append(@file_asset)
      @asset2.save
      @file_asset.containers(:response_format=>:id_array).should == [@asset3.pid,@asset2.pid]
      #has_collection_member + has_part + is_part_of
      @file_asset.part_of_append(@asset1)
      @file_asset.containers(:response_format=>:id_array).should == [@asset3.pid,@asset2.pid,@asset1.pid]
    end
  end

  describe ".containers_ids" do
    it "should return an array of container ids instead of objects" do
       #test all possible combinations...
      #none
      @file_asset.containers_ids.should == []
      #is_part_of
      @file_asset.part_of_append(@asset1)
      @file_asset.containers_ids.should == [@asset1.pid]
    end
  end

   describe ".to_solr" do
    it "should load base fields correctly if active_fedora_model is FileAsset" do
      @file_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      solr_doc = @file_asset.to_solr
      solr_doc["title_t"].should == ["testing"]
    end

    it "should not load base fields twice for FileAsset if active_fedora_model is a class that is child of FileAsset" do
      @image_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      #call Solrizer::Indexer.create_document since that produces the problem
      @image_asset.save
      solr_doc = ImageAsset.find_by_solr(@image_asset.pid).hits.first
      solr_doc["title_t"].should == ["testing"]
      @audio_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      #call Solrizer::Indexer.create_document since that produces the problem
      @audio_asset.save
      solr_doc = AudioAsset.find_by_solr(@audio_asset.pid).hits.first
      solr_doc["title_t"].should == ["testing"]
      @video_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      #call Solrizer::Indexer.create_document since that produces the problem
      @video_asset.save
      solr_doc = VideoAsset.find_by_solr(@video_asset.pid).hits.first
      solr_doc["title_t"].should == ["testing"]
    end

    it "should load base fields for FileAsset for model_only if active_fedora_model is not FileAsset but is not child of FileAsset" do
      file_asset = FileAsset.load_instance(@dummy_file_asset.pid)
      ENABLE_SOLR_UPDATES = false
      #it should save change to Fedora, but not solr
      file_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      file_asset.save
      ENABLE_SOLR_UPDATES = true
      solr_doc = DummyFileAsset.find_by_solr(@dummy_file_asset.pid).hits.first
      solr_doc["title_t"].nil?.should == true
      @dummy_file_asset.update_index
      solr_doc = DummyFileAsset.find_by_solr(@dummy_file_asset.pid).hits.first
      solr_doc["title_t"].should == ["testing"]
    end
  end
end
