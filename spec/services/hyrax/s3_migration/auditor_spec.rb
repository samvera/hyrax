# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration::Auditor do
  subject(:result) { described_class.new(original:, storage:).call }

  let(:content) { 'bytes in s3' }
  let(:identifier) { Valkyrie::ID.new('shrine://fs1/uuid') }
  let(:recorded_size) { [content.bytesize] }
  let(:checksum) { [Digest::MD5.hexdigest(content)] }
  let(:original) { double('original', file_identifier: identifier, recorded_size:, checksum:) }
  let(:s3_file) { double('s3_file', size: content.bytesize) }
  let(:storage) { double('storage', find_by: s3_file) }

  before do
    allow(s3_file).to receive(:checksum) { |digests:| digests.map { |digest| digest.update(content).to_s } }
  end

  it 'is ok when size and checksum match' do
    expect(result.status).to eq :ok
    expect(result.problems).to be_empty
  end

  context 'when the file is still on disk' do
    let(:identifier) { Valkyrie::ID.new('disk:///x') }

    it { expect(result.status).to eq :not_in_s3 }
  end

  context 'when the size differs' do
    let(:recorded_size) { [content.bytesize + 1] }

    it 'reports the size problem' do
      expect(result.status).to eq :problem
      expect(result.problems.first).to match(/size/)
    end
  end

  context 'when the stored MD5 differs' do
    let(:checksum) { [Digest::MD5.hexdigest('other')] }

    it 'reports the checksum problem' do
      expect(result.status).to eq :problem
      expect(result.problems.first).to match(/md5/)
    end
  end

  context 'when there is no recorded size or checksum' do
    let(:recorded_size) { [] }
    let(:checksum) { [] }

    it { expect(result.status).to eq :ok }
  end
end
