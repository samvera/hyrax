module CurationConcerns
  # This Service is an implementation of the Hydra::Derivatives::PersistOutputFileService
  # It supports directly contained files
  class PersistDirectlyContainedOutputFileService < Hydra::Derivatives::PersistBasicContainedOutputFileService
    # This method conforms to the signature of the .call method on Hydra::Derivatives::PersistOutputFileService
    # * Persists the file within the DirectContainer specified by :container
    #
    # @param [#read] stream the data to be persisted
    # @param [Hash] directives directions which can be used to determine where to persist to.
    # @option directives [String] url URI for the parent object.
    # @option directives [String] container Name of the container association.
    def self.call(stream, directives)
      file = Hydra::Derivatives::IoDecorator.new(stream, new_mime_type(directives.fetch(:format)))
      o_name = determine_original_name(file)
      m_type = determine_mime_type(file)
      uri = URI(directives.fetch(:url))
      raise ArgumentError, "#{uri} is not an http uri" unless uri.scheme == 'http'
      file_set = ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri.to_s))
      remote_file = file_set.send("build_#{directives.fetch(:container)}".to_sym)
      remote_file.content = file
      remote_file.mime_type = m_type
      remote_file.original_name = o_name
      file_set.save
    end
  end
end
