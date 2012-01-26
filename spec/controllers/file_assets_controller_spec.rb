require 'spec_helper'

describe FileAssetsController do
  describe "#upload" do
    before do
      sign_in FactoryGirl.create(:user)
      @file_count = GenericFile.count
      @mock = GenericFile.new({:pid => 'test:123'})
      GenericFile.expects(:new).returns(@mock)
    end
    after do
      @mock.delete
    end
    it "should create and save a file asset from the given params" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :Filedata=>[file], :Filename=>"The world"
      response.should redirect_to(catalog_index_path)
      GenericFile.count.should == @file_count + 1 
      saved_file = GenericFile.find('test:123')
      saved_file.label.should == 'world.png'
      saved_file.content.checksum.should == '28da6259ae5707c68708192a40b3e85c'
      saved_file.content.dsChecksumValid.should be_true
    end
  end

end
