# frozen_string_literal: true

module Wings
  class FileNode < ::Valkyrie::Resource
    # TODO: Branch valkyrie6 included the valkyrie resource access controls.  Including this now causes an exception.
    #       Need to explore whether this line should be uncommented.
    # include ::Valkyrie::Resource::AccessControls
    # attribute :alternate_id, ::Valkyrie::Types::Set # AF::File metadata_node id

    attribute :file_set_id, ::Valkyrie::Types::ID

    attribute :label, ::Valkyrie::Types::Set # AF::File metadata_node label
    attribute :mime_type, ::Valkyrie::Types::Set # AF::File metadata_node mime_type
    attribute :format_label, ::Valkyrie::Types::Set # AF::File metadata_node format_label e.g. "JPEG Image"
    attribute :height, ::Valkyrie::Types::Set # AF::File metadata_node height
    attribute :width, ::Valkyrie::Types::Set # AF::File metadata_node width
    attribute :checksum, ::Valkyrie::Types::Set # AF::File metadata_node original_checksum
    attribute :size, ::Valkyrie::Types::Set # AF::File metadata_node file_size
    attribute :original_filename, ::Valkyrie::Types::Set # AF::File metadata_node file_name
    attribute :file_identifiers, ::Valkyrie::Types::Set # AF::File metadata_node
    attribute :use, ::Valkyrie::Types::Set # AF::File type
    attribute :member_ids, ::Valkyrie::Types::Set

    # TODO: Determine which of the AF::File metadata_node.attributes should be included here.
    # {"id"=>
    #      "http://127.0.0.1:8984/rest/dev/gh/93/gz/48/gh93gz487/files/759c2660-3b62-41a2-b453-d41366595062",
    #  "mime_type"=>[],
    #  "label"=>[],
    #  "file_name"=>[],
    #  "file_size"=>[],
    #  "date_created"=>[],
    #  "date_modified"=>[],
    #  "byte_order"=>[],
    #  "file_hash"=>[],
    #  "bit_depth"=>[],
    #  "channels"=>[],
    #  "data_format"=>[],
    #  "frame_rate"=>[],
    #  "bit_rate"=>[],
    #  "duration"=>[],
    #  "sample_rate"=>[],
    #  "offset"=>[],
    #  "format_label"=>[],
    #  "well_formed"=>[],
    #  "valid"=>[],
    #  "fits_version"=>[],
    #  "exif_version"=>[],
    #  "original_checksum"=>[],
    #  "file_title"=>[],
    #  "creator"=>[],
    #  "page_count"=>[],
    #  "language"=>[],
    #  "word_count"=>[],
    #  "character_count"=>[],
    #  "line_count"=>[],
    #  "character_set"=>[],
    #  "markup_basis"=>[],
    #  "markup_language"=>[],
    #  "paragraph_count"=>[],
    #  "table_count"=>[],
    #  "graphics_count"=>[],
    #  "compression"=>[],
    #  "height"=>[],
    #  "width"=>[],
    #  "color_space"=>[],
    #  "profile_name"=>[],
    #  "profile_version"=>[],
    #  "orientation"=>[],
    #  "color_map"=>[],
    #  "image_producer"=>[],
    #  "capture_device"=>[],
    #  "scanning_software"=>[],
    #  "gps_timestamp"=>[],
    #  "latitude"=>[],
    #  "longitude"=>[],
    #  "aspect_ratio"=>[]}

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
