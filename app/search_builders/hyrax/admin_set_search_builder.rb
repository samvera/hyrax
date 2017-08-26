module Hyrax
  ### Allows :deposit as a valid type
  class AdminSetSearchBuilder < ::SearchBuilder
    # This skips the filter added by FilterSuppressed
    self.default_processor_chain -= [:only_active_works]

    # @param [#repository,#blacklight_config,#current_ability] context
    # @param [Symbol] access one of :edit, :read, or :deposit
    def initialize(context, access)
      @access = access
      super(context)
    end

    # This overrides the models in FilterByType
    def models
      [::AdminSet]
    end

    # Overrides Hydra::AccessControlsEnforcement
    def discovery_permissions
      if @access == :edit
        @discovery_permissions ||= ["edit"]
      else
        super
      end
    end

    # If :deposit access is requested, check to see which admin sets the user has
    # deposit or manage access to.
    # @return [Array<String>] a list of filters to apply to the solr query
    def gated_discovery_filters
      return super if @access != :deposit
      ["{!terms f=id}#{source_ids_for_deposit.join(',')}"]
    end

    delegate :source_ids_for_deposit, to: :current_ability
    private :source_ids_for_deposit
  end
end
