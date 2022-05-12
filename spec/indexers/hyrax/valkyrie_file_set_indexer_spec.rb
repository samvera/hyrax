# frozen_string_literal: true
RSpec.describe Hyrax::ValkyrieFileSetIndexer do
  include Hyrax::FactoryHelpers

  let(:fileset_id) { 'fs1' }
  let(:file_set) do
    Hyrax::FileSet.new(
      id: fileset_id,
      file_ids: [mock_file.id, mock_text.id],
      original_file_id: mock_file.id,
      thumbnail_id: mock_thumbnail.id,
      extracted_text_id: mock_text.id,
      contributor: ['Rogers, Jacqueline'],
      creator: ['Cleary, Beverly'],
      title: ['Ramona Quimby, age 8'],
      description: ["Ramona's life as an 8 year old."],
      publisher: ['HarperCollins'],
      date_created: ['1981-01-01'],
      date_uploaded: Date.parse('2011-01-01'),
      date_modified: Date.parse('2012-01-01'),
      subject: ['Family life'],
      language: ['English'],
      license: ['In Copyright'],
      rights_statement: ['Known Copyright'],
      resource_type: ['Book'],
      identifier: ['urn:isbn:1234567890'],
      based_near: ['Oakland, California'],
      related_url: ['https://id.loc.gov/resources/works/17452360.html']
    )
  end

  let(:file_name) { 'mock_file.jpg' }
  let(:original_file_id) { 'mf1' }
  let(:mock_file) do
    Hyrax::FileMetadata.new(metadata_attrs)
  end

  let(:metadata_attrs) do
    {
      file_identifier: 'VALFILEID1',
      alternate_ids: ['AFFILEID1'],
      file_set_id: fileset_id,

      label: [file_name],
      original_filename: file_name,
      mime_type: 'image/jpeg',
      type: [Hyrax::FileMetadata::Use::ORIGINAL_FILE],

      # attributes set by fits
      format_label: ['JPEG Image'],
      size: ['2904'],
      well_formed: ['true'],
      valid: ['true'],
      date_created: ['1981-01-01'],
      fits_version: ['1.5'],
      exif_version: ['2.32'],
      checksum: ['C0H9E8CfK6SbUcMd'],

      # shared attributes across multiple file types
      frame_rate: ['30/s'],
      bit_rate: ['1 Mbit/s'],
      duration: ['6:18'],
      sample_rate: ['48 kHz'],

      height: ['500'],
      width: ['600'],

      # attributes set by fits for audio files
      bit_depth: ['32'],
      channels: ['4'],
      data_format: ['mp3'],
      offset: ['7:33'],

      # attributes set by fits for documents
      file_title: ['Ramona Quimby, age 8'],
      creator: ['Cleary, Beverly'],
      page_count: ['1'],
      language: ['en'],
      word_count: ['20'],
      character_count: ['200'],
      line_count: ['4'],
      character_set: ['latin1'],
      markup_basis: ['md basis'],
      paragraph_count: ['2'],
      markup_language: ['md'],
      table_count: ['3'],
      graphics_count: ['5'],

      # attributes set by fits for images
      byte_order: ['AVR32'],
      compression: ['lossy'],
      color_space: ['sRGB'],
      profile_name: ['ESXi-7.0.2-17630552-standard'],
      profile_version: ['17630552'],
      orientation: ['landscape'],
      color_map: ['autumn'],
      image_producer: ['MemoryImageSource'],
      capture_device: ['Nikon 35mm'],
      scanning_software: ['scanningsoftwareREAL'],
      gps_timestamp: ['2021:03:11 09:35:02'],
      latitude: ['38.8951'],
      longitude: ['-77.0365'],

      # attributes set by fits for video
      aspect_ratio: ['5:4']
    }
  end

  let(:mock_text) do
    mock_file_factory(content: "abcxyz")
  end

  let(:mock_thumbnail) do
    Hyrax::FileMetadata.new(
      id: SecureRandom.uuid,
      file_set_id: fileset_id,
      type: [Hyrax::FileMetadata::Use::THUMBNAIL]
    )
  end

  let(:indexer) { described_class.new(resource: file_set) }

  describe '#to_solr' do
    before do
      allow(file_set).to receive(:persisted?).and_return(true)
      allow(file_set).to receive(:label).and_return('CastoriaAd.tiff')
      allow(Hyrax.custom_queries).to receive(:find_original_file).with(file_set: file_set).and_return(mock_file)
      allow(mock_file).to receive(:file_name).and_return(file_name)
    end
    subject { indexer.generate_solr_document }

    it 'has fields' do # rubocop:disable RSpec/ExampleLength
      expect(subject['generic_type_si']).to eq 'FileSet'
      # from core metadata
      expect(subject['title_sim']).to eq ['Ramona Quimby, age 8']
      expect(subject['title_tesim']).to eq ['Ramona Quimby, age 8']

      # from basic metadata
      expect(subject['based_near_sim']).to eq ['Oakland, California']
      expect(subject['based_near_tesim']).to eq ['Oakland, California']
      expect(subject['creator_tesim']).to eq ['Cleary, Beverly']
      expect(subject['date_created_tesim']).to eq ['1981-01-01']
      expect(subject['related_url_tesim']).to eq ['https://id.loc.gov/resources/works/17452360.html']
      expect(subject['resource_type_sim']).to eq ['Book']
      expect(subject['resource_type_tesim']).to eq ['Book']
      expect(subject['subject_sim']).to eq ['Family life']
      expect(subject['subject_tesim']).to eq ['Family life']

      # from FileSet metadata
      expect(subject['file_ids_ssim']).to match_array [mock_file.id.to_s, mock_text.id.to_s]
      expect(subject['original_file_id_ssi']).to eq mock_file.id.to_s
      expect(subject['extracted_text_id_ssi']).to eq mock_text.id.to_s
      expect(subject['hasRelatedMediaFragment_ssim']).to eq fileset_id
      expect(subject['hasRelatedImage_ssim']).to eq mock_thumbnail.id.to_s

      # from ThumbnailIndexer
      expect(subject['thumbnail_path_ss']).to eq "/derivative/#{mock_thumbnail.id}"

      # from FileMetadata
      expect(subject['original_file_alternate_ids_tesim']).to eq mock_file['alternate_ids']
      expect(subject['original_filename_tesi']).to eq mock_file['original_filename']
      expect(subject['original_filename_ssi']).to eq mock_file['original_filename']
      expect(subject['mime_type_tesi']).to eq mock_file['mime_type']
      expect(subject['mime_type_ssi']).to eq mock_file['mime_type']

      expect(subject['file_format_tesim']).to eq 'jpeg (JPEG Image)'
      expect(subject['file_format_sim']).to eq 'jpeg (JPEG Image)'
      expect(subject['file_size_lts']).to eq mock_file.size[0]
      expect(subject['type_tesim']).to eq ['http://pcdm.org/use#OriginalFile']

      # attributes set by fits
      expect(subject['format_label_tesim']).to eq mock_file['format_label']
      expect(subject['size_tesim']).to eq mock_file['size']
      expect(subject['well_formed_tesim']).to eq mock_file['well_formed']
      expect(subject['valid_tesim']).to eq mock_file['valid']
      expect(subject['date_created_tesim']).to eq mock_file['date_created']
      expect(subject['fits_version_tesim']).to eq mock_file['fits_version']
      expect(subject['exif_version_tesim']).to eq mock_file['exif_version']
      expect(subject['checksum_tesim']).to eq mock_file['checksum']

      # shared attributes across multiple file types
      expect(subject['frame_rate_tesim']).to eq mock_file['frame_rate']
      expect(subject['bit_rate_tesim']).to eq mock_file['bit_rate']
      expect(subject['duration_tesim']).to eq mock_file['duration']
      expect(subject['sample_rate_tesim']).to eq mock_file['sample_rate']

      expect(subject['height_tesim']).to eq mock_file['height']
      expect(subject['width_tesim']).to eq mock_file['width']

      # attributes set by fits for audio files
      expect(subject['bit_depth_tesim']).to eq mock_file['bit_depth']
      expect(subject['channels_tesim']).to eq mock_file['channels']
      expect(subject['data_format_tesim']).to eq mock_file['data_format']
      expect(subject['offset_tesim']).to eq mock_file['offset']

      # attributes set by fits for documents
      expect(subject['file_title_tesim']).to eq mock_file['file_title']
      expect(subject['creator_tesim']).to eq mock_file['creator']
      expect(subject['page_count_tesim']).to eq mock_file['page_count']
      expect(subject['language_tesim']).to eq mock_file['language']
      expect(subject['word_count_tesim']).to eq mock_file['word_count']
      expect(subject['character_count_tesim']).to eq mock_file['character_count']
      expect(subject['line_count_tesim']).to eq mock_file['line_count']
      expect(subject['character_set_tesim']).to eq mock_file['character_set']
      expect(subject['markup_basis_tesim']).to eq mock_file['markup_basis']
      expect(subject['paragraph_count_tesim']).to eq mock_file['paragraph_count']
      expect(subject['markup_language_tesim']).to eq mock_file['markup_language']
      expect(subject['table_count_tesim']).to eq mock_file['table_count']
      expect(subject['graphics_count_tesim']).to eq mock_file['graphics_count']

      # attributes set by fits for images
      expect(subject['byte_order_tesim']).to eq mock_file['byte_order']
      expect(subject['compression_tesim']).to eq mock_file['compression']
      expect(subject['color_space_tesim']).to eq mock_file['color_space']
      expect(subject['profile_name_tesim']).to eq mock_file['profile_name']
      expect(subject['profile_version_tesim']).to eq mock_file['profile_version']
      expect(subject['orientation_tesim']).to eq mock_file['orientation']
      expect(subject['color_map_tesim']).to eq mock_file['color_map']
      expect(subject['image_producer_tesim']).to eq mock_file['image_producer']
      expect(subject['capture_device_tesim']).to eq mock_file['capture_device']
      expect(subject['scanning_software_tesim']).to eq mock_file['scanning_software']
      expect(subject['gps_timestamp_tesim']).to eq mock_file['gps_timestamp']
      expect(subject['latitude_tesim']).to eq mock_file['latitude']
      expect(subject['longitude_tesim']).to eq mock_file['longitude']

      # attributes set by fits for video
      expect(subject['aspect_ratio_tesim']).to eq mock_file['aspect_ratio']
    end

    context "when original_file is not versioned" do
      # before do
      #   allow(version_graph).to receive(:fedora_versions).and_return([])
      # end

      it "does not have version info indexed" do
        expect(subject['original_file_id_ssi']).to eq file_set.original_file_id
      end
    end
  end

  describe '#file_format' do
    subject { indexer.send(:file_format, mock_file) }

    context 'when both mime and format_label are present' do
      before do
        allow(mock_file).to receive(:mime_type).and_return('image/png')
        allow(mock_file).to receive(:format_label).and_return(['Portable Network Graphics'])
      end
      it { is_expected.to eq 'png (Portable Network Graphics)' }
    end

    context 'when just mime type is present' do
      before do
        allow(mock_file).to receive(:mime_type).and_return('image/png')
        allow(mock_file).to receive(:format_label).and_return([])
      end
      it { is_expected.to eq 'png' }
    end

    context 'when just format_label is present' do
      before do
        allow(mock_file).to receive(:mime_type).and_return('')
        allow(mock_file).to receive(:format_label).and_return(['Portable Network Graphics'])
      end
      it { is_expected.to eq ['Portable Network Graphics'] }
    end
  end
end
