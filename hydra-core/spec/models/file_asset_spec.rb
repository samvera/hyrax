require 'spec_helper'

describe FileAsset do
  
  before(:each) do
    @file_asset = FileAsset.new
    @file_asset.stub(:create_date).and_return("2008-07-02T05:09:42.015Z")
    @file_asset.stub(:modified_date).and_return("2008-09-29T21:21:52.892Z")
  end
  
  it "Should be a kind of ActiveFedora::Base" do
    @file_asset.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should include Hydra Model Methods" do
    @file_asset.class.included_modules.should include(Hydra::ModelMethods)
    @file_asset.should respond_to(:apply_depositor_metadata)
  end
  
  describe 'label' do
    asset = FileAsset.new
    asset.label = 'image.jp2'
    asset.label.should == 'image.jp2'
  end


  describe 'add_file' do
    it "should set the dsid, mimetype and content" do
      file_name = "my_file.foo"
      mock_file = "File contents"
      @file_asset.should_receive(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype", :dsid=>'bar')
      @file_asset.should_receive(:set_title_and_label).with( file_name, :only_if_blank=>true )
      @file_asset.should_receive(:mime_type).with(file_name).and_return("mymimetype")
      @file_asset.add_file(mock_file, 'bar', file_name)
    end
  end
end
