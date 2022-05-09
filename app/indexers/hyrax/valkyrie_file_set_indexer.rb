# frozen_string_literal: true

module Hyrax
  ##
  # Indexes Hyrax::FileSet objects
  class ValkyrieFileSetIndexer < Hyrax::ValkyrieIndexer
    include Hyrax::ResourceIndexer
    include Hyrax::PermissionIndexer
    include Hyrax::VisibilityIndexer
    include Hyrax::Indexer(:core_metadata)
    include Hyrax::Indexer(:basic_metadata)

    def to_solr # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      super.tap do |solr_doc| # rubocop:disable Metrics/BlockLength
        solr_doc['generic_type_si'] = 'FileSet'

        # Metadata from the FileSet
        solr_doc['file_ids_ssim']                = resource.file_ids&.map(&:to_s)
        solr_doc['original_file_id_ssi']         = resource.original_file_id.to_s
        solr_doc['extracted_text_id_ssi']        = resource.extracted_text_id.to_s
        solr_doc['hasRelatedMediaFragment_ssim'] = resource.representative_id.to_s
        solr_doc['hasRelatedImage_ssim']         = resource.thumbnail_id.to_s
        solr_doc['thumbnail_path_ss'] = if resource.thumbnail_id.present?
                                          Hyrax::Engine.routes.url_helpers.derivative_path(resource.thumbnail_id)
                                        else
                                          ActionController::Base.helpers.image_path 'default.png'
                                        end

        # Add in metadata from the original file.
        file_metadata = original_file
        return solr_doc unless file_metadata

        # Label is the actual file name. It's not editable by the user.
        solr_doc['original_file_alternate_ids_tesim'] = file_metadata.alternate_ids&.map(&:to_s) if file_metadata.alternate_ids.present?

        solr_doc['original_filename_tesi']  = file_metadata.original_filename if file_metadata.original_filename.present?
        solr_doc['original_filename_ssi']   = file_metadata.original_filename if file_metadata.original_filename.present?
        solr_doc['mime_type_tesi']          = file_metadata.mime_type if file_metadata.mime_type.present?
        solr_doc['mime_type_ssi']           = file_metadata.mime_type if file_metadata.mime_type.present?

        solr_doc['file_format_tesim']       = file_format(file_metadata)
        solr_doc['file_format_sim']         = file_format(file_metadata)
        solr_doc['file_size_lts']           = file_metadata.size[0]
        solr_doc['type_tesim']              = file_metadata.type.map(&:to_s) if file_metadata.type.present?

        # attributes set by fits
        solr_doc['format_label_tesim']      = file_metadata.format_label if file_metadata.format_label.present?
        solr_doc['size_tesim']              = file_metadata.size if file_metadata.size.present?
        solr_doc['well_formed_tesim']       = file_metadata.well_formed if file_metadata.well_formed.present?
        solr_doc['valid_tesim']             = file_metadata.valid if file_metadata.valid.present?
        solr_doc['fits_version_tesim']      = file_metadata.fits_version if file_metadata.fits_version.present?
        solr_doc['exif_version_tesim']      = file_metadata.exif_version if file_metadata.exif_version.present?
        solr_doc['checksum_tesim']          = file_metadata.checksum if file_metadata.checksum.present?

        # shared attributes across multiple file types
        solr_doc['frame_rate_tesim']        = file_metadata.frame_rate if file_metadata.frame_rate.present? # audio, video
        solr_doc['bit_rate_tesim']          = file_metadata.bit_rate if file_metadata.bit_rate.present? # audio, video
        solr_doc['duration_tesim']          = file_metadata.duration if file_metadata.duration.present? # audio, video
        solr_doc['sample_rate_tesim']       = file_metadata.sample_rate if file_metadata.sample_rate.present? # audio, video

        solr_doc['height_tesim']            = file_metadata.height if file_metadata.height.present? # image, video
        solr_doc['width_tesim']             = file_metadata.width if file_metadata.width.present? # image, video

        # attributes set by fits for audio files
        solr_doc['bit_depth_tesim']         = file_metadata.bit_depth if file_metadata.bit_depth.present?
        solr_doc['channels_tesim']          = file_metadata.channels if file_metadata.channels.present?
        solr_doc['data_format_tesim']       = file_metadata.data_format if file_metadata.data_format.present?
        solr_doc['offset_tesim']            = file_metadata.offset if file_metadata.offset.present?

        # attributes set by fits for documents
        solr_doc['file_title_tesim']        = file_metadata.file_title if file_metadata.file_title.present?
        solr_doc['page_count_tesim']        = file_metadata.page_count if file_metadata.page_count.present?
        solr_doc['language_tesim']          = file_metadata.language if file_metadata.language.present?
        solr_doc['word_count_tesim']        = file_metadata.word_count if file_metadata.word_count.present?
        solr_doc['character_count_tesim']   = file_metadata.character_count if file_metadata.character_count.present?
        solr_doc['line_count_tesim']        = file_metadata.line_count if file_metadata.line_count.present?
        solr_doc['character_set_tesim']     = file_metadata.character_set if file_metadata.character_set.present?
        solr_doc['markup_basis_tesim']      = file_metadata.markup_basis if file_metadata.markup_basis.present?
        solr_doc['paragraph_count_tesim']   = file_metadata.paragraph_count if file_metadata.paragraph_count.present?
        solr_doc['markup_language_tesim']   = file_metadata.markup_language if file_metadata.markup_language.present?
        solr_doc['table_count_tesim']       = file_metadata.table_count if file_metadata.table_count.present?
        solr_doc['graphics_count_tesim']    = file_metadata.graphics_count if file_metadata.graphics_count.present?

        # attributes set by fits for images
        solr_doc['byte_order_tesim']        = file_metadata.byte_order if file_metadata.byte_order.present?
        solr_doc['compression_tesim']       = file_metadata.compression if file_metadata.compression.present?
        solr_doc['color_space_tesim']       = file_metadata.color_space if file_metadata.color_space.present?
        solr_doc['profile_name_tesim']      = file_metadata.profile_name if file_metadata.profile_name.present?
        solr_doc['profile_version_tesim']   = file_metadata.profile_version if file_metadata.profile_version.present?
        solr_doc['orientation_tesim']       = file_metadata.orientation if file_metadata.orientation.present?
        solr_doc['color_map_tesim']         = file_metadata.color_map if file_metadata.color_map.present?
        solr_doc['image_producer_tesim']    = file_metadata.image_producer if file_metadata.image_producer.present?
        solr_doc['capture_device_tesim']    = file_metadata.capture_device if file_metadata.capture_device.present?
        solr_doc['scanning_software_tesim'] = file_metadata.scanning_software if file_metadata.scanning_software.present?
        solr_doc['gps_timestamp_tesim']     = file_metadata.gps_timestamp if file_metadata.gps_timestamp.present?
        solr_doc['latitude_tesim']          = file_metadata.latitude if file_metadata.latitude.present?
        solr_doc['longitude_tesim']         = file_metadata.longitude if file_metadata.longitude.present?

        # attributes set by fits for video
        solr_doc['aspect_ratio_tesim']      = file_metadata.aspect_ratio if file_metadata.aspect_ratio.present?
      end
    end

    private

    def original_file
      Hyrax.custom_queries.find_original_file(file_set: resource)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      Hyrax.custom_queries.find_files(file_set: resource).first
    end

    def file_format(file)
      if file.mime_type.present? && file.format_label.present?
        "#{file.mime_type.split('/').last} (#{file.format_label.join(', ')})"
      elsif file.mime_type.present?
        file.mime_type.split('/').last
      elsif file.format_label.present?
        file.format_label
      end
    end
  end
end
