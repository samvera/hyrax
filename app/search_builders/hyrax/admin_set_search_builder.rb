# frozen_string_literal: true
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
      Hyrax::ModelRegistry.admin_set_classes
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
      ["{!terms f=id}#{admin_set_ids_for_deposit.join(',')}"]
    end

    private

    # IDs of admin_sets into which a user can deposit.
    #
    # @return [Array<String>] IDs of admin_sets into which the user can deposit
    # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
    def admin_set_ids_for_deposit
      Hyrax::Collections::PermissionsService.source_ids_for_deposit(ability: current_ability)
    end
  end
end
