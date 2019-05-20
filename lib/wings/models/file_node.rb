# frozen_string_literal: true

module Wings
  class FileNode < ::Valkyrie::Resource
    # TODO: Branch valkyrie6 included the valkyrie resource access controls.  Including this now causes an exception.
    #       Need to explore whether this line should be uncommented.
    # include ::Valkyrie::Resource::AccessControls
    attribute :label, ::Valkyrie::Types::Set
    attribute :mime_type, ::Valkyrie::Types::Set
    attribute :format_label, ::Valkyrie::Types::Set # e.g. "JPEG Image"
    attribute :height, ::Valkyrie::Types::Set
    attribute :width, ::Valkyrie::Types::Set
    attribute :checksum, ::Valkyrie::Types::Set
    attribute :size, ::Valkyrie::Types::Set
    attribute :original_filename, ::Valkyrie::Types::Set
    attribute :file_identifiers, ::Valkyrie::Types::Set
    attribute :use, ::Valkyrie::Types::Set
    attribute :member_ids, ::Valkyrie::Types::Set

    # @param [ActionDispatch::Http::UploadedFile] file
    def self.for(file:)
      new(label: file.original_filename,
          original_filename: file.original_filename,
          mime_type: file.content_type,
          use: file.try(:use) || [::Valkyrie::Vocab::PCDMUse.OriginalFile])
    end

    def original_file?
      use.include?(::Valkyrie::Vocab::PCDMUse.OriginalFile)
    end

    def thumbnail_file?
      use.include?(::Valkyrie::Vocab::PCDMUse.ThumbnailImage)
    end

    def extracted_file?
      use.include?(::Valkyrie::Vocab::PCDMUse.ExtractedImage)
    end

    def title
      label
    end

    def download_id
      id
    end

    # @return [Boolean] whether this instance is a Wings::FileNode.
    def file_node?
      true
    end

    # @return [Boolean] whether this instance is a Hydra::Works FileSet.
    def file_set?
      false
    end

    # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
    def work?
      false
    end

    # @return [Boolean] whether this instance is a Hydra::Works Collection.
    def collection?
      false
    end

    def valid?
      file.valid?(size: size.first, digests: { sha256: checksum.first.sha256 })
    end

    def file
      ::Valkyrie::StorageAdapter.find_by(id: file_identifiers.first)
    end

    def versions
      query_service = Wings::Valkyrie::QueryService.new(adapter: ::Valkyrie.config.metadata_adapter)
      query_service.find_members(resource: self, model: Wings::FileNode).to_a
    end
  end
end
