# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration::StoredChecksum do
  def original_with(*checksums)
    double('original', checksum: checksums)
  end

  let(:md5) { Digest::MD5.hexdigest('x') }
  let(:sha1) { Digest::SHA1.hexdigest('x') }
  let(:sha256) { Digest::SHA256.hexdigest('x') }

  it 'reads a bare hex string as the MD5 that FITS records' do
    stored = described_class.for(original_with(md5))

    expect([stored.algorithm, stored.digest, stored.digest_class]).to eq ['md5', md5, Digest::MD5]
  end

  it 'understands an explicit urn prefix, in any case' do
    expect(described_class.for(original_with("urn:sha1:#{sha1}")).digest_class).to eq Digest::SHA1
    expect(described_class.for(original_with("URN:SHA256:#{sha256.upcase}")).digest).to eq sha256
  end

  it 'has a readable string form' do
    expect(described_class.for(original_with(md5)).to_s).to eq "md5:#{md5}"
  end

  [
    [],
    [''],
    ['not-a-hex-digest'],
    ['urn:crc32:deadbeef'],
    ['abc123'],
    ['0123456789abcdef0123456789abcdef01234567'] # 40 hex without a prefix is not assumed to be SHA-1
  ].each do |checksums|
    it "ignores #{checksums.inspect}" do
      expect(described_class.for(original_with(*checksums))).to be_nil
    end
  end
end
