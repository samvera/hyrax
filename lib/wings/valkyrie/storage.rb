# frozen_string_literal: true

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
      LINK_HEADER = "<http://www.w3.org/ns/ldp#NonRDFSource>; rel=\"type\""
      FILES_PATH = 'files'

      attr_reader :sha1

      def initialize(connection: Ldp::Client.new(ActiveFedora.fedora.host), base_path: ActiveFedora.fedora.base_path, fedora_version: 4)
        @sha1 = fedora_version == 5 ? "sha" : "sha1"
        super
      end

      def upload(file:, original_filename:, resource:, content_type: DEFAULT_CTYPE, # rubocop:disable Metrics/ParameterLists
                 resource_uri_transformer: default_resource_uri_transformer, use: Hydra::PCDM::Vocab::PCDMTerms.File,
                 id_hint: 'original', **extra_arguments)
        id = if resource.try(:file_set?)
               upload_with_works(resource: resource, file: file, use: use)
             else
               put_file(file: file,
                        original_filename: original_filename,
                        resource: resource,
                        content_type: content_type,
                        resource_uri_transformer: resource_uri_transformer,
                        id_hint: id_hint, **extra_arguments)
             end

        find_by(id: ::Valkyrie::ID.new(id.to_s.sub(/^.+\/\//, PROTOCOL)))
      end

      private

      def digest_for(file)
        "#{sha1}=#{Digest::SHA1.file(file)}"
      end

      def default_resource_uri_transformer
        lambda do |resource, hint|
          id = [CGI.escape(resource.id), FILES_PATH, hint].join('/')
          RDF::URI.new(Hyrax.config.translate_id_to_uri.call(id))
        end
      end

      ##
      # Create a file with HTTP put; no containers here.
      # @return [String] the identifier of the created file
      def put_file(file:, original_filename:, resource:, content_type:, # rubocop:disable Metrics/ParameterLists
                   resource_uri_transformer:, id_hint:, **_extra_arguments)
        identifier = resource_uri_transformer.call(resource, id_hint)

        connection.http.put do |request|
          request.url identifier
          request.headers['Content-Type'] = content_type
          request.headers['Content-Length'] = (file.try(:size) || file.try(:length)).to_s
          request.headers['Content-Disposition'] = "attachment; filename=\"#{original_filename}\""
          request.headers['digest'] = digest_for(file)
          request.headers['link'] = LINK_HEADER
          request.body = Faraday::UploadIO.new(file, content_type, original_filename)
        end

        identifier
      end

      def upload_with_works(resource:, file:, use:)
        file_set = FileSet.find(resource.id.to_s)

        Hydra::Works::AddFileToFileSet.call(file_set, file, use)

        created_file = file_set.filter_files_by_type(use).first
        raise(StorageError, "Couldn't find a file we tried to create on #{file_set}") unless created_file

        Hyrax.config.translate_id_to_uri.call(created_file.id)
      end
    end
  end

  class StorageError < RuntimeError; end
end
