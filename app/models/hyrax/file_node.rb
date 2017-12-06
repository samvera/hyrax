# frozen_string_literal: true

module Hyrax
  class FileNode < Valkyrie::Resource
    include Valkyrie::Resource::AccessControls
    attribute :id, Valkyrie::Types::ID.optional
    attribute :label, Valkyrie::Types::Set
    attribute :mime_type, Valkyrie::Types::Set
    attribute :height, Valkyrie::Types::Set
    attribute :width, Valkyrie::Types::Set
    attribute :checksum, Valkyrie::Types::Set
    attribute :size, Valkyrie::Types::Set
    attribute :original_filename, Valkyrie::Types::Set
    attribute :file_identifiers, Valkyrie::Types::Set
    attribute :use, Valkyrie::Types::Set

    # @param [ActionDispatch::Http::UploadedFile] file
    def self.for(file:)
      new(label: file.original_filename, original_filename: file.original_filename, mime_type: file.content_type, use: file.try(:use) || [Valkyrie::Vocab::PCDMUse.OriginalFile])
    end

    def original_file?
      use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile)
    end

    def title
      label
    end

    def download_id
      id
    end

    # @return [Boolean] whether this instance is a Hyrax::FileNode.
    def file_node?
      true
    end

    # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
    def work?
      false
    end

    def valid?
      file = Valkyrie::StorageAdapter.find_by(id: file_identifiers.first)
      file.valid?(size: size.first, digests: { sha256: checksum.first.sha256 })
    end
  end
end
