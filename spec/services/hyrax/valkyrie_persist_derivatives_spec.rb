# frozen_string_literal: true
RSpec.describe Hyrax::ValkyriePersistDerivatives, valkyrie_adapter: :test_adapter do
  let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }

  before do
    allow(Hyrax.config)
      .to receive(:derivatives_path)
      .and_return('/app/samvera/hyrax-webapp/derivatives/')

    # stub out characterization to avoid system calls. It's important some
    # amount of characterization happens so listeners fire.
    allow(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_response)
  end

  describe '.call' do
    let(:directives) do
      { url: "file:///app/samvera/hyrax-webapp/derivatives/#{id}-thumbnail.jpeg" }
    end
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
    let(:id) { file_set.id }
    let(:stream) { StringIO.new('moomin') }

    it 'uploads the processed file' do
      expect { described_class.call(stream, directives) }
        .to change { Hyrax.custom_queries.find_files(file_set: file_set) }
        .from(be_empty)
    end

    context "when given a mime_type directive" do
      let(:directives) do
        { url: "file:///app/samvera/hyrax-webapp/derivatives/#{id}-mp4.mp4",
          mime_type: 'video/webm',
          container: 'service_file' }
      end

      it 'adds the mime_type to the file metadata' do
        described_class.call(stream, directives)
        files = Hyrax.custom_queries.find_files(file_set: file_set)
        file = files.first
        expect(file.mime_type).to eq 'video/webm'
        expect(file.pcdm_use).to eq [Hyrax::FileMetadata::Use::SERVICE_FILE]
      end
    end
  end

  describe '.fileset_for_directives' do
    context 'with ActiveFedora style id' do
      let(:directives) do
        { url: 'file:///app/samvera/hyrax-webapp/derivatives/95/93/tv/12/3-thumbnail.jpeg' }
      end

      it 'extracts the id' do
        expect(Hyrax.metadata_adapter.query_service)
          .to receive(:find_by).with(id: '9593tv123')
        described_class.fileset_for_directives(directives)
      end
    end

    context 'with Valkyrie style id' do
      let(:directives) do
        { url: 'file:///app/samvera/hyrax-webapp/derivatives/48/fc/01/a7/-e/df/3-/4e/d5/-a/d9/5-/32/71/3f/40/ea/ed-thumbnail.jpeg' }
      end

      it 'extracts the id' do
        expect(Hyrax.metadata_adapter.query_service)
          .to receive(:find_by).with(id: '48fc01a7-edf3-4ed5-ad95-32713f40eaed')
        described_class.fileset_for_directives(directives)
      end
    end

    context 'with many file extensions' do
      let(:directives) do
        { url: 'file:///app/samvera/hyrax-webapp/derivatives/48/fc/01/a7/-e/df/3-/4e/d5/-a/d9/5-/32/71/3f/40/ea/ed-thumbnail.svg.jp2.jpeg' }
      end

      it 'extracts the id' do
        expect(Hyrax.metadata_adapter.query_service)
          .to receive(:find_by).with(id: '48fc01a7-edf3-4ed5-ad95-32713f40eaed')
        described_class.fileset_for_directives(directives)
      end
    end

    context 'with unknown style id' do
      let(:directives) do
        { url: 'file:///app/samvera/hyrax-webapp/derivatives/what.jpeg' }
      end

      it 'raises an error' do
        expect { described_class.fileset_for_directives(directives) }
          .to raise_error(/Could not extract fileset id from path/)
      end
    end

    context 'with an id' do
      let(:directives) do
        { url: '123' }
      end

      it 'extracts the id' do
        expect(Hyrax.metadata_adapter.query_service)
          .to receive(:find_by).with(id: '123')
        described_class.fileset_for_directives(directives)
      end
    end
  end
end
