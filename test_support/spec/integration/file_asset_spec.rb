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
  end
  after(:each) do
    begin
    @file_asset.delete
    rescue
    end
  end
  describe "with parts" do
    before(:each) do
      @asset1 = ActiveFedora::Base.new
      @asset2 = ActiveFedora::Base.new
      @asset1.save
      @asset2.save
    end

    after(:each) do
      begin
      @asset1.delete
      rescue
      end
      begin
      @asset2.delete
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
      end
    end

    describe ".container_id" do    
      it "should return asset container objects via is_part_of relationships" do
        #none
        @file_asset.container_id.should be_nil
        #is_part_of
        @file_asset.container = @asset1
        @file_asset.container_id.should == @asset1.pid
      end
    end
  end

  describe ".to_solr" do
    it "should load base fields correctly if active_fedora_model is FileAsset" do
      @file_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      solr_doc = @file_asset.to_solr
      solr_doc["title_t"].should == ["testing"]
    end

    describe "with many kinds of assets" do
      before(:each) do
        @image_asset = ImageAsset.new
        @audio_asset = AudioAsset.new
        @video_asset = VideoAsset.new
        @image_asset.save
        @audio_asset.save
        @video_asset.save
      end
      after do
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
      end 
      it "should not load base fields twice for FileAsset if active_fedora_model is a class that is child of FileAsset" do
  ## It's updating DC and descMetadata, because both have title.
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
    end
    it "should load base fields for FileAsset for model_only if active_fedora_model is not FileAsset but is not child of FileAsset" do
      pending "I'm unconvinced as to the usefullness of this test. Why create as one type then reload as another? - Justin"
      @dummy_file_asset = DummyFileAsset.new
      @dummy_file_asset.save
      file_asset = FileAsset.load_instance(@dummy_file_asset.pid)
      ENABLE_SOLR_UPDATES = false
      #it should save change to Fedora, but not solr
      file_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      file_asset.save
      ENABLE_SOLR_UPDATES = true
      solr_doc = DummyFileAsset.find_by_solr(@dummy_file_asset.pid).hits.first
      solr_doc["title_t"].should be_nil
      @dummy_file_asset.update_index
      solr_doc = DummyFileAsset.find_by_solr(@dummy_file_asset.pid).hits.first
      solr_doc["title_t"].should == ["testing"]
      begin
      @dummy_file_asset.delete
      rescue
      end
    end
  end
end
