module Sufia
  module BlacklightOverride
    def render_bookmarks_control?
      false
    end

    def url_for_document doc, options = {}
      if (doc.is_a?(SolrDocument) && doc.hydra_model == 'Collection')
        [collections, doc]
      else
        [sufia, doc]
      end
    end
  
    def render_constraints_query(localized_params = params)
      # So simple don't need a view template, we can just do it here.
      scope = localized_params.delete(:route_set) || self
      return "".html_safe if localized_params[:q].blank?

      render_constraint_element(constraint_query_label(localized_params),
            localized_params[:q],
            :classes => ["query"],
            :remove => scope.url_for(localized_params.merge(:q=>nil, :action=>'index')))
    end

  end
end
