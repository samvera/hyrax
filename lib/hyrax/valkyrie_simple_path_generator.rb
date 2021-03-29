# frozen_string_literal: true
module Hyrax
  ##
  # Provide "simple", paths for the valkyrie disk storage adapter.
  #
  # By default, Valkyrie does bucketed/pairtree style paths. Since some of our
  # older on-disk file storage does not do this, we need this to provide
  # backward compatibility.
  class ValkyrieSimplePathGenerator
    attr_reader :base_path

    def initialize(base_path:)
      @base_path = base_path
    end

    def generate(resource:, file:, original_filename:) # rubocop:disable Lint/UnusedMethodArgument
      Pathname.new(base_path).join(resource.id, original_filename)
    end
  end
end
