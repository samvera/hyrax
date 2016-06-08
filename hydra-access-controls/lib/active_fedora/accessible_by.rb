ActiveFedora::QueryMethods.module_eval do
  extend ActiveSupport::Concern
  included do
    include Hydra::AccessControlsEnforcement
  end

  def accessible_by(ability, action = :index)
    permission_types = case action
      when :index then [:discover, :read, :edit]
      when :show, :read then [:read, :edit]
      when :update, :edit, :create, :new, :destroy then [:edit]
    end

    filters = gated_discovery_filters(permission_types, ability).join(" OR ")
    spawn.where!(filters)
  end
end

ActiveFedora::Querying.module_eval do
  delegate :accessible_by, :to=>:all
end
