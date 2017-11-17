# frozen_string_literal: true

# Class for Apache Tika based file characterization service
# defines the Apache Tika based characterization service a ValkyrieFileCharacterization service
# @since 3.0.0
module Hyrax
  class TikaFileCharacterizationService
    attr_reader :file_set, :persister
    def initialize(file_set:, persister:)
      @file_set = file_set
      @persister = persister
    end

    # characterizes the file_node passed into this service
    # Default options are:
    #   save: true
    # @param save [Boolean] should the persister save the file_node after Characterization
    # @return [FileNode]
    # @example characterize a file and persist the changes by default
    #   Valkyrie::FileCharacterizationService.for(file_node, persister).characterize
    # @example characterize a file and do not persist the changes
    #   Valkyrie::FileCharacterizationService.for(file_node, persister).characterize(save: false)
    def characterize(save: true)
      result = JSON.parse(json_output).last
      @file_characterization_attributes = {
        width: result['tiff:ImageWidth'],
        height: result['tiff:ImageLength'],
        mime_type: result['Content-Type'],
        checksum: MultiChecksum.for(file_object),
        size: result['Content-Length']
      }
      new_file = original_file.new(@file_characterization_attributes.to_h)
      @file_set.file_nodes = @file_set.file_nodes.reject { |x| x.id == new_file.id } + [new_file]
      @persister.save(resource: @file_set) if save
      @file_set
    end

    def json_output
      "[#{RubyTikaApp.new(filename.to_s).to_json.gsub('}{', '},{')}]"
    end

    # Determines the location of the file on disk for the file_node
    # @return Pathname
    def filename
      return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
    end

    # Provides the file attached to the file_node
    # @return Valkyrie::StorageAdapter::File
    def file_object
      @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
    end

    def original_file
      @file_set.original_file
    end

    def valid?
      true
    end

    # Class for updating characterization attributes on the FileNode
    class FileCharacterizationAttributes < Dry::Struct
      attribute :width, Valkyrie::Types::Int
      attribute :height, Valkyrie::Types::Int
      attribute :mime_type, Valkyrie::Types::String
      attribute :checksum, Valkyrie::Types::String
    end
  end
end
