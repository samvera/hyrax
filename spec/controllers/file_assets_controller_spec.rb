require 'spec_helper'

describe FileAssetsController do
  describe "#upload" do
    before do
      sign_in FactoryGirl.create(:user)
      @file_count = GenericFile.count
    end
    it "should create and save a file asset from the given params" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :Filedata=>[file], :Filename=>"The world"
      response.should redirect_to(catalog_index_path)
      GenericFile.count.should == @file_count + 1 
      GenericFile.find(:all).last.label.should == 'world.png'
      
    end
  end

end
