RSpec.describe Hyrax::MimeTypeService do
  describe '.pdf?' do
    it 'is true when pdf mimetype' do
      expect(described_class.pdf?('application/pdf')).to be true
    end
    it 'is false when not a pdf mimetype' do
      expect(described_class.pdf?('image/jpeg')).to be false
    end
  end

  describe '.image?' do
    it 'is true when image mimetype' do
      expect(described_class.image?('image/jpeg')).to be true
    end
    it 'is false when not a image mimetype' do
      expect(described_class.image?('video/mp4')).to be false
    end
  end

  describe '.video?' do
    it 'is true when video mimetype' do
      expect(described_class.video?('video/mp4')).to be true
    end
    it 'is false when not a video mimetype' do
      expect(described_class.video?('audio/mp3')).to be false
    end
  end

  describe '.audio?' do
    it 'is true when audio mimetype' do
      expect(described_class.audio?('audio/mp3')).to be true
    end
    it 'is false when not a audio mimetype' do
      expect(described_class.audio?('application/msword')).to be false
    end
  end

  describe '.office_document?' do
    it 'is true when office_document mimetype' do
      expect(described_class.office_document?('application/msword')).to be true
    end
    it 'is false when not a office_document mimetype' do
      expect(described_class.office_document?('application/pdf')).to be false
    end
  end

  describe '.image_mime_types' do
    it 'returns the image mimetypes' do
      expect(described_class.image_mime_types).to match_array ['image/png', 'image/jpeg', 'image/jpg', 'image/jp2', 'image/bmp', 'image/gif', 'image/tiff']
    end
  end

  describe '.pdf_mime_types' do
    it 'returns the pdf mimetypes' do
      expect(described_class.pdf_mime_types).to match_array ['application/pdf']
    end
  end

  describe '.video_mime_types' do
    it 'returns the video mimetypes' do
      expect(described_class.video_mime_types).to match_array ['video/mpeg', 'video/mp4', 'video/webm', 'video/x-msvideo', 'video/avi', 'video/quicktime', 'application/mxf']
    end
  end

  describe '.audio_mime_types' do
    it 'returns the audio mimetypes' do
      expect(described_class.audio_mime_types).to match_array ['audio/mp3', 'audio/mpeg', 'audio/wav', 'audio/x-wave', 'audio/x-wav', 'audio/ogg']
    end
  end

  describe '.office_document_mime_types' do
    it 'returns the image mimetypes' do
      expect(described_class.office_document_mime_types).to match_array ['text/rtf',
                                                                         'application/msword',
                                                                         'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                                                         'application/vnd.oasis.opendocument.text',
                                                                         'application/vnd.ms-excel',
                                                                         'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                                                         'application/vnd.ms-powerpoint',
                                                                         'application/vnd.openxmlformats-officedocument.presentationml.presentation']
    end
  end
end
