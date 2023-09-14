# frozen_string_literal: true

require 'faraday/multipart'

module Wings
  module Valkyrie
    ##
    # This is a Wings storage adapter designed for compatibility with
    # Hydra::Pcdm/Hydra::Works.
    #
    # Where the built-in `Valkyrie::Storage::Fedora` adapter uploads files
    # without LDP containment relationships (via HTTP PUT), this adapter
    # supports adding files to a `/files` container when a `FileSet` is
    # passed as the `resource:` argument.
    #
    # If a non `#file_set?` resource is passed, the logic is very similar to the
    # built-in storage adapter.
    #
    # For use with Hyrax, this adapter defaults to Fedora 4.
    class Storage < ::Valkyrie::Storage::Fedora
      DEFAULT_CTYPE = 'application/octet-stream'
      FILES_PATH = 'files'

      def initialize(connection: Ldp::Client.new(ActiveFedora.fedora.host), base_path: ActiveFedora.fedora.base_path, fedora_version: 4)
        super
      end

      ##
      # @api private
      def self.cast_to_valkyrie_id(id)
        ::Valkyrie::ID.new(id.to_s.sub(/^.+\/\//, PROTOCOL))
      end

      def upload(file:, original_filename:, resource:, content_type: DEFAULT_CTYPE, # rubocop:disable Metrics/ParameterLists
                 resource_uri_transformer: default_resource_uri_transformer, use: Hydra::PCDM::Vocab::PCDMTerms.File, # rubocop:disable Lint/UnusedMethodArgument
                 id_hint: 'original', **_extra_arguments)
        id = if resource.try(:file_set?)
               upload_with_works(resource: resource, file: file, use: use)
             else
               return super(file: file, original_filename: original_filename, resource: resource, content_type: content_type, resource_uri_transformer: resource_uri_transformer_factory(id_hint))
             end
        find_by(id: cast_to_valkyrie_id(id))
      end

      private

      def default_resource_uri_transformer
        lambda do |resource, hint|
          id = [CGI.escape(resource.id), FILES_PATH, hint].join('/')
          RDF::URI.new(Hyrax.config.translate_id_to_uri.call(id))
        end
      end

      # Transforms default_resource_uri_transformer to conform to Valkyrie's
      # expected interface of passing a resource and base url.
      def resource_uri_transformer_factory(hint)
        lambda do |resource, _base_url|
          default_resource_uri_transformer.call(resource, hint)
        end
      end

      def upload_with_works(resource:, file:, use:)
        file_set = FileSet.find(resource.id.to_s)

        Hydra::Works::AddFileToFileSet.call(file_set, file, use)

        created_file = file_set.filter_files_by_type(use).first
        raise(StorageError, "Couldn't find a file we tried to create on #{file_set}") unless created_file

        Hyrax.config.translate_id_to_uri.call(created_file.id)
      end

      def cast_to_valkyrie_id(id)
        self.class.cast_to_valkyrie_id(id)
      end
    end
  end

  class StorageError < RuntimeError; end
end
