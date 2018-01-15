ActiveFedora::QueryMethods.module_eval do
  extend ActiveSupport::Concern

  def accessible_by(ability, action = :index)
    permission_types = case action
      when :index then [:discover, :read, :edit]
      when :show, :read then [:read, :edit]
      when :update, :edit, :create, :new, :destroy then [:edit]
    end

    filters = gated_discovery_filters(permission_types, ability).join(" OR ")
    spawn.where!(filters)
  end

  private

    def gated_discovery_filters(types, ability)
      search_builder = Hydra::AccessControls::SearchBuilder.new(self,
                                                                ability: ability,
                                                                permission_types: types)
      search_builder.send(:gated_discovery_filters)
    end
end

ActiveFedora::Querying.module_eval do
  delegate :accessible_by, :to=>:all
end
