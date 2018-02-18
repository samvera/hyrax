module Hyrax
  # A work should be able to be filtered out of search results if it's inactive
  module Suppressible
    extend ActiveSupport::Concern

    included do
      # This holds the workflow state
      property :state, predicate: Vocab::FedoraResourceStatus.objState, multiple: false
    end

    ##
    # Used to restrict visibility on search results for a work that is inactive. If the state is not set, the
    # default behavior is to consider the work not to be suppressed.
    #
    # Override this method if you have some criteria by which records should not display in the search results.
    def suppressed?
      return false if state.nil?

      state == Vocab::FedoraResourceStatus.inactive
    end

    def to_sipity_entity
      raise "Can't create an entity until the model has been persisted" unless persisted?
      @sipity_entity ||= Sipity::Entity.find_by(proxy_for_global_id: to_global_id.to_s)
    end
  end
end
