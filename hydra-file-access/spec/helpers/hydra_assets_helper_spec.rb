require 'spec_helper'

describe HydraAssetsHelper do
  before :all do
    @behavior = Hydra::HydraAssetsHelperBehavior.deprecation_behavior
    Hydra::HydraAssetsHelperBehavior.deprecation_behavior = :silence
  end

  after :all do
    Hydra::HydraAssetsHelperBehavior.deprecation_behavior = @behavior
  end
  include HydraAssetsHelper
  
  describe "get_file_asset_count" do
    describe "with outbound has_part" do
      before do
        @asset_object4 =ModsAsset.new
        @file_object1 = ModsAsset.create
        @asset_object4.add_relationship(:has_part,@file_object1)
        @asset_object4.save
      end
      after do
        @asset_object4.delete
        @file_object1.delete
      end
      it "should find one" do
        #outbound has_part
        doc = ModsAsset.find_by_solr(@asset_object4.pid).first
        get_file_asset_count(doc).should == 1
      end
    end

    describe "with has_part and inbound is_part_of" do
      before do
        @asset_object5 =ModsAsset.create
        @file_object1 = FileAsset.create
        @file_object2 = FileAsset.create
        @file_object2.container = @asset_object5
        @asset_object5.add_relationship(:has_part,@file_object1)
        @asset_object5.save
        @file_object2.save
      end
      after do
        @asset_object5.delete
        @file_object1.delete
        @file_object2.delete
      end
      it "should find two" do
        doc = ActiveFedora::Base.find_by_solr(@asset_object5.pid).first
        get_file_asset_count(doc).should == 2
      end
    end

    describe "with inbound is_part_of" do
      before do
        @asset_object6 =ModsAsset.create
        @file_object1 = FileAsset.create
        @file_object1.container = @asset_object6
        @asset_object6.save
        @file_object1.save
      end
      after do
        @asset_object6.delete
        @file_object1.delete
      end
      it "should find one" do
        doc = ActiveFedora::Base.find_by_solr(@asset_object6.pid).first
        get_file_asset_count(doc).should == 1
      end
    end

    describe "with inbound is_part_of" do
      before do
        @asset_object7 =ModsAsset.create
      end
      after do
        @asset_object7.delete
      end
      it "should find zero" do
        doc = ActiveFedora::Base.find_by_solr(@asset_object7.pid).first
        get_file_asset_count(doc).should == 0
      end
    end
  end

end
