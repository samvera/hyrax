require 'spec_helper'

describe FileContentDatastream do
  before do
    Sufia.queue.stub(:push).with(an_instance_of CharacterizeJob) #don't run characterization
  end
  describe "version control" do
    before do
      f = GenericFile.new
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      f.apply_depositor_metadata('mjg36')
      f.stub(:characterize_if_changed).and_yield #don't run characterization
      f.save
      @file = f.reload
    end
    after do
      @file.delete
    end
    it "should have a list of versions with one entry" do
      @file.content.versions.count == 1
    end
    it "should return the expected version ID" do
      @file.content.versions.first.versionID.should == "content.0"
    end
    it "should support latest_version" do
      @file.content.latest_version.versionID.should == "content.0"
    end
    it "should return the same version via get_version" do
      @file.content.get_version("content.0").versionID.should == @file.content.latest_version.versionID
    end
    it "should not barf when a garbage ID is provided to get_version"  do
      @file.content.get_version("foobar").should be_nil
    end
    describe "add a version" do
      before do
        @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
        @file.stub(:characterize_if_changed).and_yield #don't run characterization
        @file.save
      end
      it "should return two versions" do
        @file.content.versions.count == 2
      end
      it "should return the newer version via latest_version" do
        @file.content.versions.first.versionID.should == "content.1"
      end
      it "should return the same version via get_version" do
        @file.content.get_version("content.1").versionID.should == @file.content.latest_version.versionID
      end
    end
  end
  describe "extract_metadata" do
    before do
      @subject = FileContentDatastream.new(nil, 'content')
      @subject.stub(:pid=>'my_pid')
      @subject.stub(:dsVersionID=>'content.7')
    end
    it "should return an xml document", :unless => $in_travis do
      repo = double("repo")
      repo.stub(:config=>{})
      f = File.new(fixture_path + '/world.png')
      content = double("file")
      content.stub(:read=>f.read)
      content.stub(:rewind=>f.rewind)
      @subject.stub(:content).and_return(f)
      xml = @subject.extract_metadata
      doc = Nokogiri::XML.parse(xml)
      doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text.should == '50'
    end
    it "should return expected results when invoked via HTTP", :unless => $in_travis do
      repo = double("repo")
      repo.stub(:config=>{})
      f = ActionDispatch::Http::UploadedFile.new(:tempfile => File.new(fixture_path + '/world.png'),
                                                 :filename => 'world.png')
      content = double("file")
      content.stub(:read=>f.read)
      content.stub(:rewind=>f.rewind)
      @subject.stub(:content).and_return(f)
      xml = @subject.extract_metadata
      doc = Nokogiri::XML.parse(xml)
      doc.root.xpath('//ns:identity/@mimetype', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).first.value.should == 'image/png'
    end
  end
  describe "changed?" do
    before do
      @generic_file = GenericFile.new
      @generic_file.apply_depositor_metadata('mjg36')
      @generic_file.stub(:characterize_if_changed).and_yield #don't run characterization
    end
    after do
      @generic_file.delete
    end
    it "should only return true when the datastream has actually changed" do
      @generic_file.add_file(File.open(fixture_path + '/world.png', 'rb'), 'content', 'world.png')
      @generic_file.content.changed?.should be_true
      @generic_file.save!
      @generic_file.content.changed?.should be_false

      # Add a thumbnail ds
      @generic_file.add_file(File.open(fixture_path + '/world.png'), 'thumbnail', 'world.png')
      @generic_file.thumbnail.changed?.should be_true
      @generic_file.content.changed?.should be_false

      retrieved_file = @generic_file.reload
      retrieved_file.content.changed?.should be_false
    end
  end
end
