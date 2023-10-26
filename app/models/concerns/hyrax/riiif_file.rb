# frozen_string_literal: true
module Hyrax
  # Adds file locking to Riiif::File
  # @see RiiifFileResolver
  class RiiifFile < Riiif::File
    include ActiveSupport::Benchmarkable

    attr_reader :id
    def initialize(input_path, tempfile = nil, id:)
      super(input_path, tempfile)
      raise(ArgumentError, "must specify id") if id.blank?
      @id = id
    end

    # Wrap extract in a read lock and benchmark it
    def extract(transformation, image_info = nil)
      Riiif::Image.file_resolver.file_locks[id].with_read_lock do
        benchmark "RiiifFile extracted #{path} with #{transformation.to_params}", level: :debug do
          super
        end
      end
    end

    private

    def logger
      Hyrax.logger
    end
  end
end
