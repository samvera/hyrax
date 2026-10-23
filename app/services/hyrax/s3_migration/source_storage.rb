# frozen_string_literal: true

module Hyrax
  module S3Migration
    # The Valkyrie storage adapter whose files are moved to S3. Only a plain Valkyrie::Storage::Disk is
    # supported: versioned disk keeps versions and deletion markers that a copy to S3 would lose.
    module SourceStorage
      class Unsupported < StandardError; end

      class << self
        attr_writer :adapter_name

        # @return [Symbol] the name the source adapter is registered under (default :disk)
        def adapter_name
          @adapter_name ||= :disk
        end

        # @return [Valkyrie::Storage::Disk]
        # @raise [Unsupported] when no such adapter is registered, or it is not a plain disk adapter
        def adapter
          found = Valkyrie::StorageAdapter.find(adapter_name)
          return found if found.is_a?(Valkyrie::Storage::Disk)

          raise Unsupported, "The :#{adapter_name} storage adapter is a #{found.class}. Only Valkyrie::Storage::Disk (disk:// ids) " \
                             'can be migrated; see documentation/migrating-files-to-s3.md.'
        rescue Valkyrie::StorageAdapter::AdapterNotFoundError
          raise Unsupported, "No Valkyrie storage adapter is registered as :#{adapter_name} (registered: " \
                             "#{Valkyrie::StorageAdapter.storage_adapters.keys.join(', ')}). Set " \
                             'Hyrax::S3Migration::SourceStorage.adapter_name to the plain disk adapter that holds the files.'
        end

        # @param identifier [#to_s] a file identifier
        def handles?(identifier)
          adapter.handles?(id: Valkyrie::ID.new(identifier.to_s))
        end

        def path_for(identifier)
          adapter.file_path(identifier)
        end

        def base_path
          adapter.base_path.to_s
        end
      end
    end
  end
end
