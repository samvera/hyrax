# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Provides a model‐specific subclass for
    # +Hyrax::Indexers::PcdmObjectIndexer+.
    #
    # The base Hyrax engine could get on without this, but it’s useful for
    # downstream applications and reflects what we do for forms.
    def self.PcdmObjectIndexer(work_class) # rubocop:disable Naming/MethodName
      Class.new(Hyrax::Indexers::PcdmObjectIndexer) do
        @model_class = work_class

        class << self
          attr_reader :model_class

          ##
          # @return [String]
          def inspect
            return "Hyrax::Indexers::PcdmObjectIndexer(#{model_class})" if name.blank?
            super
          end
        end
      end
    end

    ##
    # @api public
    #
    # Returns the indexer class associated with a given model.
    def self.ResourceIndexer(model_class) # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity, Naming/MethodName
      @resource_indexers ||= {}.compare_by_identity
      @resource_indexers[model_class] ||=
        # +#respond_to?+ needs to be used here, not +#try+, because Dry::Types
        # overrides the latter??
        if model_class.respond_to?(:pcdm_collection?) && model_class.pcdm_collection?
          if model_class <= Hyrax::AdministrativeSet
            Hyrax.config.administrative_set_indexer
          else
            Hyrax.config.pcdm_collection_indexer
          end
        elsif model_class.respond_to?(:pcdm_object?) && model_class.pcdm_object?
          if model_class.respond_to?(:file_set?) && model_class.file_set?
            Hyrax.config.file_set_indexer
          else
            Hyrax.config.pcdm_object_indexer_builder.call(model_class)
          end
        else
          Hyrax::Indexers::ResourceIndexer
        end
    end
  end
end
