# frozen_string_literal: true

module Hyrax
  ##
  # Propagates visibility from a given Work to its FileSets
  class FileSetVisibilityPropagator
    ##
    # @!attribute [rw] source
    #   @return [#visibility]
    attr_accessor :source

    ##
    # @param source [#visibility] the object to propagate visibility from
    def initialize(source:)
      self.source = source
    end

    ##
    # @return [void]
    #
    # @raise [RuntimeError] if visibility propagation fails
    def propagate
      source.file_sets.each do |file|
        file.visibility = source.visibility # visibility must come first, because it can clear an embargo/lease
        copy_visibility_modifier(source: source, file: file, modifier: :lease)
        copy_visibility_modifier(source: source, file: file, modifier: :embargo)
        file.save!
      end
    end

    private

    def copy_visibility_modifier(source:, file:, modifier:)
      source_modifier = source.public_send(modifier)
      return unless source_modifier
      file.public_send("build_#{modifier}") unless file.public_send(modifier)
      file.public_send(modifier).attributes = source_modifier.attributes.except('id')
      file.public_send(modifier).save
    end
  end
end
