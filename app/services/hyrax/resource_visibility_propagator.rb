# frozen_string_literal: true

module Hyrax
  ##
  # Propagates visibility from a valkyrie Work to its FileSets
  class ResourceVisibilityPropagator
    ##
    # @!attribute [rw] source
    #   @return [#visibility]
    attr_accessor :source

    ##
    # @!attribute [r] persister
    #   @return [#save]
    # @!attribute [r] queries
    #   @return [Valkyrie::Persistence::CustomQueryContainer]
    attr_reader :persister, :queries

    ##
    # @param source [#visibility] the object to propogate visibility from
    def initialize(source:,
                   persister: Hyrax.persister,
                   queries:   Hyrax.query_service.custom_queries)
      @persister  = persister
      @queries    = queries
      self.source = source
    end

    ##
    # @return [void]
    #
    # @raise [RuntimeError] if visibility propogation fails
    def propagate
      queries.find_child_filesets(resource: source).each do |file_set|
        file_set.visibility = source.visibility

        persister.save(resource: file_set)
      end
    end
  end
end
