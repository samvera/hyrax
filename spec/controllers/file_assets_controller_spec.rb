require 'spec_helper'

describe FileAssetsController do
  describe "#upload" do
    before do
      sign_in FactoryGirl.create(:user)
      @file_count = GenericFile.count
      ActiveFedora::RubydoraConnection.any_instance.expects(:nextid).returns('test:123')
    end
    after do
      GenericFile.find('test:123').delete
    end
    it "should create and save a file asset from the given params" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :Filedata=>[file], :Filename=>"The world"
      response.should redirect_to(catalog_index_path)
      GenericFile.count.should == @file_count + 1 
      saved_file = GenericFile.find('test:123')
      saved_file.label.should == 'world.png'
#      saved_file.checksum.should == 'abcdef1234'
    end
  end

end
