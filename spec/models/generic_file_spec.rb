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
    @file.descMetadata.should be_kind_of GammaRDFDatastream
  end
  it "should have content datastream" do
    @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
    @file.content.should be_kind_of FileContentDatastream
  end
  it "should support to_solr" do
    @file.to_solr.should_not be_nil
  end
  describe "delegations" do
    it "should delegate methods to descriptive metadata" do
      @file.should respond_to(:related_url)
      @file.should respond_to(:based_near)
      @file.should respond_to(:part_of)
      @file.should respond_to(:contributor)
      @file.should respond_to(:creator)
      @file.should respond_to(:title)
      @file.should respond_to(:description)
      @file.should respond_to(:publisher)
      @file.should respond_to(:date_created)
      @file.should respond_to(:date_uploaded)
      @file.should respond_to(:date_modified)
      @file.should respond_to(:subject)
      @file.should respond_to(:language)
      @file.should respond_to(:date)
      @file.should respond_to(:rights)
      @file.should respond_to(:resource_type)
      @file.should respond_to(:format)
      @file.should respond_to(:identifier)
    end
    it "should delegate methods to characterization metadata" do
      @file.should respond_to(:format_label)
      @file.should respond_to(:mime_type)
      @file.should respond_to(:file_size)
      @file.should respond_to(:last_modified)
      @file.should respond_to(:filename)
      @file.should respond_to(:original_checksum)
      @file.should respond_to(:well_formed)
      @file.should respond_to(:file_title)
      @file.should respond_to(:file_author)
      @file.should respond_to(:page_count)
    end
    it "should be able to set values via delegated methods" do
      @file.related_url = "http://example.org/"
      @file.creator = "John Doe"
      @file.title = "New work"
      @file.save
      f = GenericFile.find(@file.pid)
      f.related_url.should == ["http://example.org/"]
      f.creator.should == ["John Doe"]
      f.title.should == ["New work"]
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
  
  describe "label" do
    it "should set the inner label" do
      @file.label = "My New Label"
      @file.inner_object.label.should == "My New Label"
    end
    it "should set the title IF it is not already set" do
      pending
      @file.label = "My New Label"
      @file.title.should == "My New Label"
      @file.label = "My Newest Label!"
      @file.inner_object.label.should == "My Newest Label!"
      @file.title.should == "My New Label"
    end
  end
end
