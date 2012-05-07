require 'spec_helper'

describe FileContentDatastream do
  before do
    @subject = FileContentDatastream.new(nil, 'content')
    @subject.stubs(:pid=>'my_pid')
    @subject.stubs(:dsVersionID=>'content.7')
  end
  describe "extract_metadata" do
    it "should have the path" do
      @subject.fits_path.should_not be_nil
      @subject.fits_path.should_not == ''
    end
    it "should return an xml document" do
      repo = mock("repo")
      repo.stubs(:config=>{})
      f = File.new(Rails.root + 'spec/fixtures/world.png')
      content = mock("file")
      content.stubs(:read=>f.read)
      content.stubs(:rewind=>f.rewind)
      @subject.expects(:content).times(5).returns(f)
      xml = @subject.extract_metadata
      doc = Nokogiri::XML.parse(xml)
      doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text.should == '50'
    end
    it "should return expected results when invoked via HTTP" do
      repo = mock("repo")
      repo.stubs(:config=>{})
      f = ActionDispatch::Http::UploadedFile.new(:tempfile => File.new(Rails.root + 'spec/fixtures/world.png'),
                                                 :filename => 'world.png')
      content = mock("file")
      content.stubs(:read=>f.read)
      content.stubs(:rewind=>f.rewind)
      @subject.expects(:content).times(5).returns(f)
      xml = @subject.extract_metadata
      doc = Nokogiri::XML.parse(xml)
      doc.root.xpath('//ns:identity/@mimetype', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).first.value.should == 'image/png'
    end
  end
  describe "changed?" do
    before do
      @generic_file = GenericFile.new
    end
    after do
      @generic_file.delete
    end
    it "should only return true when the datastream has actually changed" do
      @generic_file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @generic_file.content.changed?.should be_true
      @generic_file.save
      @generic_file.content.changed?.should be_false

      # Add a thumbnail ds
      @generic_file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'thumbnail')
      @generic_file.thumbnail.changed?.should be_true
      @generic_file.content.changed?.should be_false

      retrieved_file = GenericFile.find(@generic_file.pid)
      retrieved_file.content.changed?.should be_false
    end
  end
end
