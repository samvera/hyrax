module My
  class HighlightsController < MyController

    self.search_params_logic += [
      :show_only_highlighted_files
    ]

    def index
      super
      @selected_tab = :highlighted
    end
  
    protected
    
    def search_action_url *args
      sufia.dashboard_highlights_url *args
    end

  end
end
