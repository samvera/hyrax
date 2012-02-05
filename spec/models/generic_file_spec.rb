require 'spec_helper'

describe GenericFile do
  before(:each) do 
    @file = GenericFile.new
  end 
  it "should have rightsMetadata" do
    @file.rightsMetadata.should be_instance_of Hydra::RightsMetadata
  end
  it "should have apply_depositor_metadata" do
    @file.apply_depositor_metadata('jcoyne')
    @file.rightsMetadata.edit_access.should == ['jcoyne']
  end
  it "should have a characterization datastream" do
    @file.characterization.should be_kind_of FitsDatastream
  end 
  it "should have a dc desc metadata" do
    @file.descMetadata.should be_kind_of ActiveFedora::DCRDFDatastream
  end
  it "should have content datastream" do
    @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
    @file.content.should be_kind_of FileContentDatastream
  end
  describe "collection" do
    before(:each) do 
      @user = User.create(:login => "testuser", 
                          :email => "testuser@example.com", 
                          :password => "password", 
                          :password_confirmation => "password")
      @collection = Collection.create(:name => "my_collection",
                                      :user => @user)
    end
    it "should contain one file" do
      @collection.should respond_to(:generic_files)
      @collection << @file
      @collection.should include(@file)
      @file.collection.should == @collection
    end
  end
  describe "characterize" do
    it "should run when the content datastream is created" do
      @file.expects(:characterize)
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.save
    end
    it "should return expected results when called" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.characterize
      doc = Nokogiri::XML.parse(@file.characterization.content)
      doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text.should == '50'
    end
  end
end
