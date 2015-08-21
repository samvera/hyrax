class FitsDatastream < ActiveFedora::OmDatastream
  include OM::XML::Document

  set_terminology do |t|
    t.root(path: 'fits',
           xmlns: 'http://hul.harvard.edu/ois/xml/ns/fits/fits_output',
           schema: 'http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd')
    t.identification do
      t.identity do
        t.format_label(path: { attribute: 'format' })
        t.mime_type(path: { attribute: 'mimetype' })
      end
    end
    t.fileinfo do
      t.file_size(path: 'size')
      t.last_modified(path: 'lastmodified')
      t.filename(path: 'filename')
      t.original_checksum(path: 'md5checksum')
      t.rights_basis(path: 'rightsBasis')
      t.copyright_basis(path: 'copyrightBasis')
      t.copyright_note(path: 'copyrightNote')
    end
    t.filestatus do
      t.well_formed(path: 'well-formed')
      t.valid(path: 'valid')
      t.status_message(path: 'message')
    end
    t.metadata do
      t.document do
        t.file_title(path: 'title')
        t.file_author(path: 'author')
        t.file_language(path: 'language')
        t.page_count(path: 'pageCount')
        t.word_count(path: 'wordCount')
        t.character_count(path: 'characterCount')
        t.paragraph_count(path: 'paragraphCount')
        t.line_count(path: 'lineCount')
        t.table_count(path: 'tableCount')
        t.graphics_count(path: 'graphicsCount')
      end
      t.image do
        t.byte_order(path: 'byteOrder')
        t.compression(path: 'compressionScheme')
        t.width(path: 'imageWidth')
        t.height(path: 'imageHeight')
        t.color_space(path: 'colorSpace')
        t.profile_name(path: 'iccProfileName')
        t.profile_version(path: 'iccProfileVersion')
        t.orientation(path: 'orientation')
        t.color_map(path: 'colorMap')
        t.image_producer(path: 'imageProducer')
        t.capture_device(path: 'captureDevice')
        t.scanning_software(path: 'scanningSoftwareName')
        t.exif_version(path: 'exifVersion')
        t.gps_timestamp(path: 'gpsTimeStamp')
        t.latitude(path: 'gpsDestLatitude')
        t.longitude(path: 'gpsDestLongitude')
      end
      t.text do
        t.character_set(path: 'charset')
        t.markup_basis(path: 'markupBasis')
        t.markup_language(path: 'markupLanguage')
      end
      t.audio do
        t.duration(path: 'duration')
        t.bit_depth(path: 'bitDepth')
        t.sample_rate(path: 'sampleRate')
        t.channels(path: 'channels')
        t.data_format(path: 'dataFormatType')
        t.offset(path: 'offset')
      end
      t.video do
        t.width(path: 'imageWidth')
        t.height(path: 'imageHeight')
        t.duration(path: 'duration')
        t.sample_rate(path: 'sampleRate')
        t.frame_rate(path: 'frameRate')
      end
    end
    t.format_label(proxy: [:identification, :identity, :format_label])
    t.mime_type(proxy: [:identification, :identity, :mime_type])
    t.file_size(proxy: [:fileinfo, :file_size])
    t.last_modified(proxy: [:fileinfo, :last_modified])
    t.filename(proxy: [:fileinfo, :filename])
    t.original_checksum(proxy: [:fileinfo, :original_checksum])
    t.rights_basis(proxy: [:fileinfo, :rights_basis])
    t.copyright_basis(proxy: [:fileinfo, :copyright_basis])
    t.copyright_note(proxy: [:fileinfo, :copyright_note])
    t.well_formed(proxy: [:filestatus, :well_formed])
    t.valid(proxy: [:filestatus, :valid])
    t.status_message(proxy: [:filestatus, :status_message])
    t.file_title(proxy: [:metadata, :document, :file_title])
    t.file_author(proxy: [:metadata, :document, :file_author])
    t.page_count(proxy: [:metadata, :document, :page_count])
    t.file_language(proxy: [:metadata, :document, :file_language])
    t.word_count(proxy: [:metadata, :document, :word_count])
    t.character_count(proxy: [:metadata, :document, :character_count])
    t.paragraph_count(proxy: [:metadata, :document, :paragraph_count])
    t.line_count(proxy: [:metadata, :document, :line_count])
    t.table_count(proxy: [:metadata, :document, :table_count])
    t.graphics_count(proxy: [:metadata, :document, :graphics_count])
    t.byte_order(proxy: [:metadata, :image, :byte_order])
    t.compression(proxy: [:metadata, :image, :compression])
    t.width(proxy: [:metadata, :image, :width])
    t.video_width(proxy: [:metadata, :video, :width])
    t.height(proxy: [:metadata, :image, :height])
    t.video_height(proxy: [:metadata, :video, :height])
    t.color_space(proxy: [:metadata, :image, :color_space])
    t.profile_name(proxy: [:metadata, :image, :profile_name])
    t.profile_version(proxy: [:metadata, :image, :profile_version])
    t.orientation(proxy: [:metadata, :image, :orientation])
    t.color_map(proxy: [:metadata, :image, :color_map])
    t.image_producer(proxy: [:metadata, :image, :image_producer])
    t.capture_device(proxy: [:metadata, :image, :capture_device])
    t.scanning_software(proxy: [:metadata, :image, :scanning_software])
    t.exif_version(proxy: [:metadata, :image, :exif_version])
    t.gps_timestamp(proxy: [:metadata, :image, :gps_timestamp])
    t.latitude(proxy: [:metadata, :image, :latitude])
    t.longitude(proxy: [:metadata, :image, :longitude])
    t.character_set(proxy: [:metadata, :text, :character_set])
    t.markup_basis(proxy: [:metadata, :text, :markup_basis])
    t.markup_language(proxy: [:metadata, :text, :markup_language])
    t.duration(proxy: [:metadata, :audio, :duration])
    t.video_duration(proxy: [:metadata, :video, :duration])
    t.bit_depth(proxy: [:metadata, :audio, :bit_depth])
    t.sample_rate(proxy: [:metadata, :audio, :sample_rate])
    t.video_sample_rate(proxy: [:metadata, :video, :sample_rate])
    t.channels(proxy: [:metadata, :audio, :channels])
    t.data_format(proxy: [:metadata, :audio, :data_format])
    t.offset(proxy: [:metadata, :audio, :offset])
    t.frame_rate(proxy: [:metadata, :video, :frame_rate])
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.fits(xmlns: 'http://hul.harvard.edu/ois/xml/ns/fits/fits_output',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'xsi:schemaLocation' =>
    "http://hul.harvard.edu/ois/xml/ns/fits/fits_output
    http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd",
               version: '0.6.0',
               timestamp: '1/25/12 11:04 AM') do
        xml.identification { xml.identity(toolname: 'FITS') }
      end
    end
    builder.doc
  end
end
