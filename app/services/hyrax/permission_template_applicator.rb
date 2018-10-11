# frozen_string_literal: true
module Hyrax
  ##
  # Applies a `PermissionTemplate` to a given model object by adding the
  # template's manage and view users to the model's permissions.
  #
  # @example applying a template
  #   applicator = PermissionTemplateApplicator.new(template: my_template)
  #   applicator.apply_to(work)
  #
  # @example applying a template with fluent chaining syntax
  #   PermissionTemplateApplicator.apply(my_template).to work
  #
  # @since 2.4.0
  class PermissionTemplateApplicator
    ##
    # @!attribute [rw] template
    #   @return [Hyrax::PermissionTemplate]
    attr_accessor :template

    ##
    # @param template [Hyrax::PermissionTemplate]
    def initialize(template:)
      self.template = template
    end

    ##
    # @param template [Hyrax::PermissionTemplate]
    #
    # @return [PermissionTemplateApplicator]
    def self.apply(template)
      new(template: template)
    end

    ##
    # @param model [Hydra::PCDM::Object, Hydra::PCDM::Collection]
    # @return [Boolean] true if the permissions have been successfully applied
    def apply_to(model:)
      model.edit_groups += template.agent_ids_for(agent_type: 'group', access: 'manage')
      model.edit_users  += template.agent_ids_for(agent_type: 'user',  access: 'manage')
      model.read_groups += template.agent_ids_for(agent_type: 'group', access: 'view')
      model.read_users  += template.agent_ids_for(agent_type: 'user',  access: 'view')

      true
    end
    alias to apply_to
  end
end
