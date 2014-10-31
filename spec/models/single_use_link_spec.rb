require 'spec_helper'

describe SingleUseLink, :type => :model do
  before(:all) do
    @file = GenericFile.new
    @file.apply_depositor_metadata('mjg36')
    @file.save
  end

  after(:all) do
    @file.destroy
  end

  let(:file) { @file }

  describe "create" do
     before do
      @now = DateTime.now
      allow(DateTime).to receive(:now).and_return(@now)
      @hash = "sha2hash#{@now.to_f.to_s}"
      expect(Digest::SHA2).to receive(:new).and_return(@hash)
     end
     it "should create show link" do
      su = SingleUseLink.create itemId: file.pid, path: Sufia::Engine.routes.url_helpers.generic_file_path(file.pid)
      expect(su.downloadKey).to eq(@hash)
      expect(su.itemId).to eq(file.pid)
      expect(su.path).to eq(Sufia::Engine.routes.url_helpers.generic_file_path(file.pid))
      su.delete
     end
     it "should create show download link" do
      su = SingleUseLink.create itemId: file.pid, path: Sufia::Engine.routes.url_helpers.download_path(file.pid)
      expect(su.downloadKey).to eq(@hash)
      expect(su.itemId).to eq(file.pid)
      expect(su.path).to eq(Sufia::Engine.routes.url_helpers.download_path(file.pid))
      su.delete
     end
  end
  describe "find" do
     describe "not expired" do
       before do
          @su = SingleUseLink.create(downloadKey: 'sha2hashb', itemId: file.pid, path: Sufia::Engine.routes.url_helpers.download_path(file.noid), expires: DateTime.now.advance(hours: 1))
       end
       it "should retrieve link" do
          link = SingleUseLink.where(downloadKey: 'sha2hashb').first
          expect(link.itemId).to eq(file.pid)
       end
       it "should retrieve link with find_by" do
          link = SingleUseLink.find_by_downloadKey('sha2hashb')
          expect(link.itemId).to eq(file.pid)
       end
       it "should expire link" do
          link = SingleUseLink.where(downloadKey: 'sha2hashb').first
          expect(link.expired?).to eq(false)
       end
     end
     describe "expired" do
       before do
          @su = SingleUseLink.create!(downloadKey: 'sha2hashb', itemId:file.pid, path:Sufia::Engine.routes.url_helpers.download_path(file.noid))

          @su.update_attribute :expires, DateTime.now.advance(hours: -1)
       end

       it "should expire link" do
          link = SingleUseLink.where(downloadKey: 'sha2hashb').first
          expect(link.expired?).to eq(true)
       end
     end
  end
end
