module Hyrax
  ### Allows :deposit as a valid type
  class AdminSetSearchBuilder < ::SearchBuilder
    # This skips the filter added by FilterSuppressed
    self.default_processor_chain -= [:only_active_works]

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

    # We're going to check the permission_templates
    def gated_discovery_filters
      return super if @access != :deposit
      ["{!terms f=id}#{admin_set_ids.join(',')}"]
    end

    private

      # @return [Array<String>] a list of admin set ids for admin sets the current user
      #   has deposit or manage permissions to.
      def admin_set_ids
        PermissionTemplateAccess.joins(:permission_template)
                                .where(agent_type: 'user',
                                       agent_id: user,
                                       access: ['deposit', 'manage'])
                                .pluck('DISTINCT admin_set_id')
      end

      def user
        current_ability.current_user.user_key
      end
  end
end
