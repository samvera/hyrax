RSpec.describe SingleUseLink do
  let(:file) { FileSet.new(id: 'abc123') }

  describe "default attributes" do
    let(:hash) { "sha2hash#{DateTime.current.to_f}" }
    let(:path) { '/foo/file/99999' }

    subject { described_class.new item_id: '99999', path: path }

    it "creates link" do
      expect(Digest::SHA2).to receive(:new).and_return(hash)
      expect(subject.download_key).to eq hash
      expect(subject.item_id).to eq '99999'
      expect(subject.path).to eq path
    end
  end

  describe "attribute aliases" do
    let(:hash) { "sha2hash#{DateTime.current.to_f}" }
    let(:path) { '/foo/file/99999' }

    subject { described_class.new itemId: '99999', path: path }

    it "creates link" do
      expect(Digest::SHA2).to receive(:new).and_return(hash)
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
