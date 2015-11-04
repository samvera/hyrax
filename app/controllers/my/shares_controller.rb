module My
  class SharesController < MyController
    self.search_params_logic += [
      :show_only_shared_files,
      :show_only_file_sets
    ]

    def index
      super
      @selected_tab = :shared
    end

    protected

      def search_action_url(*args)
        sufia.dashboard_shares_url(*args)
      end
  end
end
