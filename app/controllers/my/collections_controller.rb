module My
  class CollectionsController < MyController

    self.search_params_logic += [
      :show_only_resources_deposited_by_current_user,
      :show_only_collections
    ]

    def index
      super
      @selected_tab = :collections
    end

    protected

    def search_action_url *args
      sufia.dashboard_collections_url *args
    end
  end
end
