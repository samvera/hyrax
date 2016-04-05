module CurationConcerns
  class FileSetIndexer < ActiveFedora::IndexingService
    include IndexesThumbnails
    STORED_INTEGER = Solrizer::Descriptor.new(:integer, :stored)

    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('hasRelatedMediaFragment', :symbol)] = object.representative_id
        solr_doc[Solrizer.solr_name('hasRelatedImage', :symbol)] = object.thumbnail_id
        # Label is the actual file name. It's not editable by the user.
        solr_doc[Solrizer.solr_name('label')] = object.label
        solr_doc[Solrizer.solr_name('label', :stored_sortable)] = object.label
        solr_doc[Solrizer.solr_name('file_format')] = file_format
        solr_doc[Solrizer.solr_name('file_format', :facetable)] = file_format
        solr_doc[Solrizer.solr_name(:file_size, STORED_INTEGER)] = object.file_size[0]
        solr_doc['all_text_timv'] = object.full_text.content
        solr_doc[Solrizer.solr_name('generic_work_ids', :symbol)] = object.generic_work_ids unless object.generic_work_ids.empty?
        solr_doc['height_is'] = Integer(object.height.first) if object.height.present?
        solr_doc['width_is'] = Integer(object.width.first) if object.width.present?
        solr_doc[Solrizer.solr_name('mime_type', :stored_sortable)] = object.mime_type
        solr_doc['thumbnail_path_ss'] = thumbnail_path
        # Index the Fedora-generated SHA1 digest to create a linkage
        # between files on disk (in fcrepo.binary-store-path) and objects
        # in the repository.
        solr_doc[Solrizer.solr_name('digest', :symbol)] = digest_from_content
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
