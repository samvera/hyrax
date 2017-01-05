module Hyrax
  class FileSetIndexer < ActiveFedora::IndexingService
    include Hyrax::IndexesThumbnails
    STORED_LONG = Solrizer::Descriptor.new(:long, :stored)

    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('hasRelatedMediaFragment', :symbol)] = object.representative_id
        solr_doc[Solrizer.solr_name('hasRelatedImage', :symbol)] = object.thumbnail_id
        # Label is the actual file name. It's not editable by the user.
        solr_doc[Solrizer.solr_name('label')] = object.label
        solr_doc[Solrizer.solr_name('label', :stored_sortable)] = object.label
        solr_doc[Solrizer.solr_name('file_format')] = file_format
        solr_doc[Solrizer.solr_name('file_format', :facetable)] = file_format
        solr_doc[Solrizer.solr_name(:file_size, STORED_LONG)] = object.file_size[0]
        solr_doc['all_text_timv'] = object.extracted_text.content if object.extracted_text.present?
        solr_doc['height_is'] = Integer(object.height.first) if object.height.present?
        solr_doc['width_is'] = Integer(object.width.first) if object.width.present?
        solr_doc[Solrizer.solr_name('mime_type', :stored_sortable)] = object.mime_type
        solr_doc['thumbnail_path_ss'] = thumbnail_path
        # Index the Fedora-generated SHA1 digest to create a linkage
        # between files on disk (in fcrepo.binary-store-path) and objects
        # in the repository.
        solr_doc[Solrizer.solr_name('digest', :symbol)] = digest_from_content
        solr_doc[Solrizer.solr_name('page_count')] = object.page_count
        solr_doc[Solrizer.solr_name('file_title')] = object.file_title
        solr_doc[Solrizer.solr_name('duration')] = object.duration
        solr_doc[Solrizer.solr_name('sample_rate')] = object.sample_rate
        solr_doc[Solrizer.solr_name('original_checksum')] = object.original_checksum
      end
    end

    private

      def digest_from_content
        return unless object.original_file
        object.original_file.digest.first.to_s
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
