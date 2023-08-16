# frozen_string_literal: true
module Hyrax
  class FileSetIndexer < ActiveFedora::IndexingService
    include Hyrax::IndexesThumbnails
    include Hyrax::IndexesBasicMetadata
    STORED_LONG = ActiveFedora::Indexing::Descriptor.new(:long, :stored)

    def generate_solr_document # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      super.tap do |solr_doc|
        solr_doc['hasRelatedMediaFragment_ssim'] = object.representative_id
        solr_doc['hasRelatedImage_ssim'] = object.thumbnail_id
        # Label is the actual file name. It's not editable by the user.
        solr_doc['label_tesim'] = object.label
        solr_doc['label_ssi']   = object.label
        solr_doc['file_format_tesim'] = file_format
        solr_doc['file_format_sim']   = file_format
        solr_doc['file_size_lts'] = object.file_size[0]
        solr_doc['all_text_timv'] = object.extracted_text.content if object.extracted_text.present?
        solr_doc['height_is'] = Integer(object.height.first) if object.height.present?
        solr_doc['width_is']  = Integer(object.width.first) if object.width.present?
        solr_doc['visibility_ssi'] = object.visibility
        solr_doc['mime_type_ssi']  = object.mime_type
        # Index the Fedora-generated SHA1 digest to create a linkage between
        # files on disk (in fcrepo.binary-store-path) and objects in the repository.
        solr_doc['digest_ssim']             = [digest_from_content]
        solr_doc['page_count_tesim']        = object.page_count
        solr_doc['file_title_tesim']        = object.file_title
        solr_doc['duration_tesim']          = object.duration
        solr_doc['sample_rate_tesim']       = object.sample_rate
        solr_doc['original_checksum_tesim'] = object.original_checksum
        solr_doc['alpha_channels_ssi']      = object.alpha_channels
        solr_doc['original_file_id_ssi']    = original_file_id
        solr_doc['extracted_text_id_ssi']   = extracted_text_id
        solr_doc['generic_type_si'] = 'FileSet'
      end
    end

    private

    def digest_from_content
      return unless object.original_file
      object.original_file.digest.first.to_s
    end

    def original_file_id
      return unless object.original_file
      Hyrax::VersioningService.versioned_file_id object.original_file
    end

    def extracted_text_id
      return unless object.extracted_text
      Hyrax::VersioningService.versioned_file_id object.extracted_text
    end

    def file_format
      if object.mime_type.present? && object.format_label.present?
        "#{object.mime_type.split('/').last} (#{object.format_label.join(', ')})"
      elsif object.mime_type.present?
        object.mime_type.split('/').last
      elsif object.format_label.present?
        object.format_label
      end
    end
  end
end
