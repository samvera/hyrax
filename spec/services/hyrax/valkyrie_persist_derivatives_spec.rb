# frozen_string_literal: true
RSpec.describe Hyrax::ValkyriePersistDerivatives do
  before do
    allow(Hyrax.config).to receive(:derivatives_path).and_return('/app/samvera/hyrax-webapp/derivatives/')
  end

  describe '.fileset_id_from_path' do
    let(:path) { "/app/samvera/hyrax-webapp/derivatives/95/93/tv/12/3-thumbnail.jpeg" }

    subject { described_class.fileset_id_from_path(path) }

    it 'returns the correct ID' do
      expect(subject).to eq "9593tv123"
    end
  end

  describe '.call' do
    let(:directives) do
      { url: 'file:///app/samvera/hyrax-webapp/derivatives/95/93/tv/12/3-thumbnail.jpeg' }
    end
    let(:fileset) { double("FileSet") }
    let(:id) { "9593tv123" }
    let(:stream) { StringIO.new }
    let(:tmpfile) { double("Tempfile") }

    before do
      allow(Tempfile).to receive(:new).and_return(tmpfile)
      allow(tmpfile).to receive(:write).with ""
      allow(Hyrax.config.derivatives_storage_adapter).to receive(:upload)
      allow(Hyrax.metadata_adapter.query_service).to receive(:find_by).and_return(fileset)
      allow(fileset).to receive(:id).with id
    end

    subject { described_class.call(stream, directives) }

    it 'uploads the processed file' do
      expect(Tempfile).to receive(:new).with(id, encoding: 'ascii-8bit')
      allow(Hyrax.metadata_adapter.query_service).to receive(:find_by).with(id: id).and_return(fileset)
      expect(Hyrax.config.derivatives_storage_adapter).to(
        receive(:upload).with(
          file: tmpfile,
          original_filename: '/app/samvera/hyrax-webapp/derivatives/95/93/tv/12/3-thumbnail.jpeg',
          resource: fileset
        )
      )
      subject
    end
  end
end
