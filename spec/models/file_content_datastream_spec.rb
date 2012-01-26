require 'spec_helper'

describe FileContentDatastream do
  before do
    @subject = FileContentDatastream.new(nil, 'content')
    @subject.stubs(:pid=>'my_pid')
    @subject.stubs(:dsVersionID=>'content.7')
  end

  describe "extract_metadata" do
    it "should return an xml document" do
      repo = mock("repo")
      repo.stubs(:config=>{})
      @subject.expects(:content).returns(File.new(Rails.root + 'spec/fixtures/world.png').read)
      xml = @subject.extract_metadata
      doc = Nokogiri::XML.parse(xml)
      doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text.should == '50'
    end
    it "should have the path" do
      @subject.fits_path.should_not be_nil
      @subject.fits_path.should_not == ''
    end
  end

  describe "logs" do
    before do
      @old = ChecksumAuditLog.create(:pid=>'my_pid', :dsid=>'content', :version=>'content.0', :pass=>true, :created_at=>2.minutes.ago)
      @new = ChecksumAuditLog.create(:pid=>'my_pid', :dsid=>'content', :version=>'content.0', :pass=>false)
      @different_ds = ChecksumAuditLog.create(:pid=>'my_pid', :dsid=>'descMetadata', :version=>'content.0', :pass=>false)
      @different_pid = ChecksumAuditLog.create(:pid=>'another_pid', :dsid=>'content', :version=>'content.0', :pass=>false)
    end
    it "should return a list of logs for this datastream sorted by date descending" do
      @subject.logs.should == [@new, @old]
    end
  end

  describe "audit" do
    describe "when dsChecksumValid is true" do
      before do
        @subject.stubs(:dsChecksumValid).returns(true)
      end
      it "should create an audit log marked pass" do
        ChecksumAuditLog.expects(:create!).with(:pass => true, :pid => 'my_pid', :version=>'content.7', :dsid => 'content')
        @subject.audit
      end
      describe "and there are old successful logs" do
        before do
          @old = ChecksumAuditLog.create(:pid=>'my_pid', :dsid=>'content', :pass=>true, :version=>'content.0', :created_at=>2.minutes.ago)
          @new = ChecksumAuditLog.create(:pid=>'my_pid', :dsid=>'content', :version=>'content.0', :pass=>true)
        end
        it "should delete the previously newest log" do
          @subject.audit
          lambda { ChecksumAuditLog.find(@new.id)}.should raise_exception ActiveRecord::RecordNotFound
          ChecksumAuditLog.find(@old.id).should_not be_nil #Keep this one
        end
      end
    end
    describe "when dsChecksumValid is false" do
      before do
        @subject.stubs(:dsChecksumValid).returns(false)
      end
      it "should create an audit log marked fail" do
        ChecksumAuditLog.expects(:create!).with(:pass => false, :pid => 'my_pid', :version=>'content.7', :dsid => 'content')
        @subject.audit
      end
    end

  end

end
