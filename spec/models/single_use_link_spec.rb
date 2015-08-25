require 'spec_helper'

describe SingleUseLink do
  before do
    @file = GenericFile.new
    @file.apply_depositor_metadata('mjg36')
    @file.save
  end

  let(:file) { @file }

  describe "create" do
    before do
      @now = DateTime.now
      allow(DateTime).to receive(:now).and_return(@now)
      @hash = "sha2hash#{@now.to_f}"
      expect(Digest::SHA2).to receive(:new).and_return(@hash)
    end
    it "creates show link" do
      su = described_class.create itemId: file.id, path: Sufia::Engine.routes.url_helpers.generic_file_path(file.id)
      expect(su.downloadKey).to eq(@hash)
      expect(su.itemId).to eq(file.id)
      expect(su.path).to eq(Sufia::Engine.routes.url_helpers.generic_file_path(file.id))
      su.delete
    end
    it "creates show download link" do
      su = described_class.create itemId: file.id, path: Sufia::Engine.routes.url_helpers.download_path(file.id)
      expect(su.downloadKey).to eq(@hash)
      expect(su.itemId).to eq(file.id)
      expect(su.path).to eq(Sufia::Engine.routes.url_helpers.download_path(file.id))
      su.delete
    end
  end
  describe "find" do
    describe "not expired" do
      before do
        @su = described_class.create(downloadKey: 'sha2hashb', itemId: file.id, path: Sufia::Engine.routes.url_helpers.download_path(file), expires: DateTime.now.advance(hours: 1))
      end
      it "retrieves link" do
        link = described_class.where(downloadKey: 'sha2hashb').first
        expect(link.itemId).to eq(file.id)
      end
      it "retrieves link with find_by" do
        link = described_class.find_by_downloadKey('sha2hashb')
        expect(link.itemId).to eq(file.id)
      end
      it "expires link" do
        link = described_class.where(downloadKey: 'sha2hashb').first
        expect(link.expired?).to eq(false)
      end
    end
    describe "expired" do
      before do
        @su = described_class.create!(downloadKey: 'sha2hashb', itemId: file.id, path: Sufia::Engine.routes.url_helpers.download_path(file))

        @su.update_attribute :expires, DateTime.now.advance(hours: -1)
      end

      it "expires link" do
        link = described_class.where(downloadKey: 'sha2hashb').first
        expect(link.expired?).to eq(true)
      end
    end
  end
end
