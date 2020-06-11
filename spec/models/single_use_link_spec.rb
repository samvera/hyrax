# frozen_string_literal: true
RSpec.describe SingleUseLink do
  subject(:link) { described_class.new item_id: '99999', path: path }
  let(:file) { FileSet.new(id: 'abc123') }
  let(:hash) { "sha2hash#{DateTime.current.to_f}" }
  let(:path) { '/foo/file/99999' }

  before do
    allow(described_class).to receive(:generate_download_key).and_return(hash)
  end

  describe "default attributes" do
    it "creates link" do
      expect(subject.download_key).to eq hash
      expect(subject.item_id).to eq '99999'
      expect(subject.path).to eq path
    end
  end

  describe "attribute aliases" do
    it "creates link" do
      expect(subject.downloadKey).to eq hash
      expect(subject.itemId).to eq '99999'
      expect(subject.path).to eq path
    end
  end

  describe "#expired?" do
    let(:link) do
      described_class.new(expires: expires)
    end

    subject { link.expired? }

    context "when not expired" do
      let(:expires) { DateTime.current.advance(hours: 1) }

      it { is_expected.to be false }
    end

    context "when not expired" do
      let(:expires) { DateTime.current.advance(hours: -1) }

      it { is_expected.to be true }
    end
  end
end
