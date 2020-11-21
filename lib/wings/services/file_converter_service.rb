# frozen_string_literal: true
# Conversion service for going between files on a valkyrie resource and files on an active fedora object
module Wings
  # @deprecated use generic Wings converters instead.
  # @see ModelTransformer, ActiveFedoraConverter
  class FileConverterService
    class << self
      def af_file_to_resource(af_file:)
        Deprecation.warn("Use ModelTransformer.for(af_file) instead.")
        ModelTransformer.for(af_file)
      end

      def resource_to_af_file(metadata_resource:)
        Deprecation.warn("Use ActiveFedoraConverter.convert(resource:) instead.")
        ActiveFedoraConverter.convert(resource: metadata_resource)
      end
    end
  end
end
