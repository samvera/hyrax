require 'spec_helper'

describe SingleUseLink do
  before(:all) do
    @file = GenericFile.new
    @file.apply_depositor_metadata('mjg36')
    @file.save
  end

  after (:all) do
    @file.delete
  end

  let(:file) do
    @file
  end
  
  describe "create" do
     before do
        @now = DateTime.now
        DateTime.stub(:now).and_return(@now)
        @hash = "sha2hash"+@now.to_f.to_s
        Digest::SHA2.should_receive(:new).and_return(@hash)
        
     end
     it "should create show link" do
        su = SingleUseLink.create itemId: file.pid, path: Sufia::Engine.routes.url_helpers.generic_file_path(file.pid)
        su.downloadKey.should == @hash
        su.itemId.should == file.pid
        su.path.should == Sufia::Engine.routes.url_helpers.generic_file_path(file.pid)
        su.delete
     end 
     it "should create show download link" do
        su = SingleUseLink.create itemId: file.pid, path: Sufia::Engine.routes.url_helpers.download_path(file.pid)
        su.downloadKey.should == @hash
        su.itemId.should == file.pid
        su.path.should == Sufia::Engine.routes.url_helpers.download_path(file.pid)
        su.delete
     end 
  end
  describe "find" do
     describe "not expired" do
       before do
          @su = SingleUseLink.create(downloadKey:'sha2hashb', itemId:file.pid, path:Sufia::Engine.routes.url_helpers.download_path(file.noid), expires:DateTime.now.advance(:hours => 1))
       end
       it "should retrieve link" do
          link = SingleUseLink.where(downloadKey:'sha2hashb').first
          link.itemId.should == file.pid
       end 
       it "should retrieve link with find_by" do
          link = SingleUseLink.find_by_downloadKey('sha2hashb')
          link.itemId.should == file.pid
       end 
       it "should expire link" do
          link = SingleUseLink.where(downloadKey:'sha2hashb').first
          link.expired?.should == false        
       end 
     end
     describe "expired" do
       before do
          @su = SingleUseLink.create!(downloadKey:'sha2hashb', itemId:file.pid, path:Sufia::Engine.routes.url_helpers.download_path(file.noid))

          @su.update_attribute :expires, DateTime.now.advance(:hours => -1)
       end

       it "should expire link" do
          link = SingleUseLink.where(downloadKey:'sha2hashb').first
          link.expired?.should == true        
       end
     end 
  end
end
