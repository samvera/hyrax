# TODO: This should live in Hyrax::AddFileNodeToFileSet service and should work for all valkyrie adapters.
module Wings::Works
  class AddFileNodeToFileSet
    # Adds a file to the file_set
    # @param file_set [Valkyrie::Resource] adding file to this file set
    # @param file_node [Valkyrie::Resource] uploaded file and its metadata
    # @param update_existing [Boolean] whether to update an existing file if there is one. When set to true, performs a create_or_update.
    #   When set to false, always creates a new file within file_set.files.
    # @param versioning [Boolean] whether to create new version entries (only applicable if file_node's +type+ corresponds to a versionable file)

    def self.call(file_set:, file_node:, file:, update_existing: true, versioning: true)
      raise ArgumentError, 'supplied object must be a file set' unless file_set.file_set?
      raise ArgumentError, 'supplied object must be a file node' unless file_node.file_node?
      raise ArgumentError, 'supplied file must respond to read' unless file.respond_to? :read

      # TODO: required as a workaround for https://github.com/samvera/active_fedora/pull/858
      # file_set.save unless file_set.persisted? # TODO: May not need to do the save first when this is a resource.

      af_file_set = Wings::ActiveFedoraConverter.new(resource: file_set).convert

      updater_class = versioning ? VersioningUpdater : Updater
      updater = updater_class.new(af_file_set, file_node, file, update_existing)
      status = updater.update
      status ? file_set : false
    end

    class Updater
      attr_reader :af_file_set, :file_node, :file, :current_file

      def initialize(af_file_set, file_node, file, update_existing)
        @af_file_set = af_file_set
        @file_node = file_node
        @file = file
        @current_file = find_or_create_file(file_node.use, update_existing)
      end

      # @param [#read] file object that will be interrogated using the methods: :path, :original_name, :original_filename, :mime_type, :content_type
      # None of the attribute description methods are required.
      def update
        attach_attributes
        persist
      end

      private

        # @param [RDF::URI] the identified use of the file (e.g. Valkyrie::Vocab::PCDMUse.OriginalFile, Valkyrie::Vocab::PCDMUse.ThumbnailImage, etc.)
        # @param [true, false] update_existing when true, try to retrieve existing element before building one
        def find_or_create_file(use, update_existing)
          current_file = af_file_set.filter_files_by_type(use).first if update_existing
          unless current_file
            af_file_set.files.build
            current_file = af_file_set.files.last
            Hydra::PCDM::AddTypeToFile.call(current_file, use)
          end
          current_file
        end

        # Persist a new file with its containing file set; otherwise, just save the file itself
        def persist
          if current_file.new_record?
            af_file_set.save
          else
            current_file.save
          end
          file_node.file_identifiers = [current_file.id.split('/')[-1]]
        end

        def attach_attributes
          current_file.content = file
          current_file.original_name = file_node.original_filename.first
          current_file.mime_type = file_node.mime_type.first
          set_metadata_node_values(current_file.metadata_node, attributes_from_file_node)
          persist
        end

        def set_metadata_node_values(metadata_node, attributes)
          metadata_node.label = attributes[:label]
          metadata_node.mime_type = attributes[:mime_type]
          metadata_node.format_label = attributes[:format_label]
          metadata_node.height = attributes[:height]
          metadata_node.width = attributes[:width]
          metadata_node.original_checksum = attributes[:checksum]
          metadata_node.file_size = attributes[:size]
          metadata_node.file_name = attributes[:original_filename]
          # TODO: May need to add others.  FileNode class definition has the full list of attrs for metadata_node
        end

        def attributes_from_file_node
          attrs = file_node.attributes.dup
          attrs.delete(:file_identifiers)
          attrs.delete(:id)
          attrs.delete(:alternate_ids)
          attrs.delete(:internal_resource)
          attrs.delete(:new_record)
          attrs.delete(:created_at)
          attrs.delete(:updated_at)
          attrs.delete(:content)
          attrs.delete(:mime_type)
          attrs.delete(:use)
          attrs.delete(:original_name)
          attrs.compact
          attrs
        end
    end

    class VersioningUpdater < Updater
      def update(*)
        super && current_file.create_version
      end
    end
  end
end
