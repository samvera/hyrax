# frozen_string_literal: true
module Hyrax
  # This Service is an implementation of the Hydra::Derivatives::PersistOutputFileService
  # It supports directly contained files
  class PersistDirectlyContainedOutputFileService < Hydra::Derivatives::PersistBasicContainedOutputFileService
    # This method conforms to the signature of the .call method on Hydra::Derivatives::PersistOutputFileService
    # * Persists the file within the DirectContainer specified by :container
    #
    # @param content [String] the data to be persisted
    # @param directives [Hash] directions which can be used to determine where to persist to.
    # @option directives [String] url URI for the parent object.
    # @option directives [String] container Name of the container association.
    def self.call(content, directives)
      file = io(content, directives)
      file_set = retrieve_file_set(directives)
      remote_file = retrieve_remote_file(file_set, directives)
      remote_file.content = file
      remote_file.mime_type = determine_mime_type(file)
      remote_file.original_name = determine_original_name(file)
      file_set.save
    end

    # @param directives [Hash] directions which can be used to determine where to persist to.
    # @option directives [String] url URI for the parent object.
    def self.retrieve_file_set(directives)
      uri = URI(directives.fetch(:url))
      if uri.is_a?(URI::HTTP)
        Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: Hyrax::Base.uri_to_id(uri.to_s), use_valkyrie: false)
      else
        raise ArgumentError, "#{uri} is not an file/http(s) uri" unless uri.is_a?(URI::File)

        fileset_for_directives(directives)
      end
    end
    private_class_method :retrieve_file_set

    # The filepath will look something like
    # /app/samvera/hyrax-webapp/derivatives/95/93/tv/12/3-thumbnail.jpeg and
    # we want to extract the FileSet id, which in this case would be 9593tv123
    #
    # @param [String] path
    # @return [Hyrax::FileSet]
    def self.fileset_for_directives(directives)
      path = URI(directives.fetch(:url)).path
      id = path.sub(Hyrax.config.derivatives_path.to_s, "")
               .delete('/')
               .match(/^(.*)-\w*(\.\w+)*$/) { |m| m[1] }
      raise "Could not extract fileset id from path #{path}" unless id

      Hyrax.metadata_adapter.query_service.find_by(id: id)
    end
    private_class_method :fileset_for_directives

    # Override this implementation if you need a remote file from a different location
    # @param file_set [FileSet] the container of the remote file
    # @param directives [Hash] directions which can be used to determine where to persist to
    # @option directives [String] container Name of the container association.
    # @return [ActiveFedora::File]
    def self.retrieve_remote_file(file_set, directives)
      file_set.send("build_#{directives.fetch(:container)}".to_sym)
    end
    private_class_method :retrieve_remote_file
  end
end
