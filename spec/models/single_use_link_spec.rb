require 'spec_helper'

describe SingleUseLink do
  let(:file) { FileSet.new(id: 'abc123') }
  let(:now) { DateTime.now }
  let(:hash) { "sha2hash#{now.to_f}" }

  describe "create" do
    subject { described_class.create itemId: file.id, path: path }

    before do
      allow(DateTime).to receive(:now).and_return(now)
      expect(Digest::SHA2).to receive(:new).and_return(hash)
    end
    after do
      subject.delete
    end

    describe "show" do
      let(:path) { Rails.application.routes.url_helpers.curation_concerns_file_set_path(file.id) }

      it "creates link" do
        expect(subject.downloadKey).to eq(hash)
        expect(subject.itemId).to eq(file.id)
        expect(subject.path).to eq(Rails.application.routes.url_helpers.curation_concerns_file_set_path(file.id))
      end
    end
    describe "download" do
      let(:path) { Rails.application.routes.url_helpers.download_path(file.id) }

      it "creates link" do
        expect(subject.downloadKey).to eq(hash)
        expect(subject.itemId).to eq(file.id)
        expect(subject.path).to eq(Rails.application.routes.url_helpers.download_path(file.id))
      end
    end
  end
  describe "find" do
    describe "not expired" do
      before do
        @su = described_class.create(downloadKey: 'sha2hashb', itemId: file.id, path: Rails.application.routes.url_helpers.download_path(file), expires: DateTime.now.advance(hours: 1))
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
        @su = described_class.create!(downloadKey: 'sha2hashb', itemId: file.id, path: Rails.application.routes.url_helpers.download_path(file))

        @su.update_attribute :expires, DateTime.now.advance(hours: -1)
      end

      it "expires link" do
        link = described_class.where(downloadKey: 'sha2hashb').first
        expect(link.expired?).to eq(true)
      end
    end
  end
end
