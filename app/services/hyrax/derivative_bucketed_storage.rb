# frozen_string_literal: true

# this class overrides the Valkyrie::Storage::Disk::BucketStorage class so that file paths match
module Hyrax
  class DerivativeBucketedStorage
    attr_reader :base_path

    def initialize(base_path:)
      @base_path = base_path
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def generate(resource:, file:, original_filename:)
      raise ArgumentError, "original_filename must be provided" unless original_filename
      Pathname.new(base_path).join(*bucketed_path(resource.id)).join(original_filename)
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def bucketed_path(id)
      # We want to use the same code the derivative process uses so that items end up
      # stored in the place we expect them.
      Hyrax::DerivativePath.new(id.to_s).pair_directory
    end
  end
end
