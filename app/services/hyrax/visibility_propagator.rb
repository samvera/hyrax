# frozen_string_literal: true
module Hyrax
  ##
  # @abstract Propagates visibility from a provided object (e.g. a Work) to some
  #   group of its members (e.g. file_sets).
  class VisibilityPropagator
    ##
    # @param source [#visibility] the object to propagate visibility from
    #
    # @return [#propagate]
    def self.for(source:)
      case source
      when ActiveFedora::Base # ActiveFedora
        FileSetVisibilityPropagator.new(source: source)
      when Hyrax::Resource # Valkyrie
        # Due to performance issues for a Hyrax::Resource in Fedora 6,
        # use a job that copies both permissions and visibility instead
        # of reloading and iterating again.
        ResourcePermissionsVisibilityPropagator.new(source: source)
      else
        NullVisibilityPropagator.new(source: source)
      end
    end

    ##
    # Provides a null/logging implementation of the visibility propagator.
    class NullVisibilityPropagator
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
      # @raise [RuntimeError] if we're in development mode
      def propagate
        message =  "Tried to propagate visibility to members of #{source} " \
                   "but didn't know what kind of object it is. Model " \
                   "name #{source.try(:model_name)}. Called from #{caller[0]}."

        Hyrax.logger.warn(message)
        Rails.env.development? ? raise(message) : :noop
      end
    end
  end
end
