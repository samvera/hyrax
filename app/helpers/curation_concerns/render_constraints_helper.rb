module CurationConcerns
  module RenderConstraintsHelper
    # TODO: we can remove this override when we can depend on https://github.com/projectblacklight/blacklight/pull/1398
    def render_constraints_query(localized_params = params)
      # So simple don't need a view template, we can just do it here.
      return "".html_safe if localized_params[:q].blank?

      render_constraint_element(constraint_query_label(localized_params),
                                localized_params[:q],
                                classes: ["query"],
                                remove: remove_constraint_url(localized_params))
    end

    # This overrides Blacklight to remove the 'search_field' tag from the
    # localized params when the query is cleared. This is because unlike
    # Blacklight, there is no control to change the search_field in the
    # curation_concerns UI
    def remove_constraint_url(localized_params)
      scope = localized_params.delete(:route_set) || self
      options = localized_params.merge(q: nil, action: 'index')
                                .except(*fields_to_exclude_from_constraint_element)
      options.permit!
      scope.url_for(options)
    end

    # @return [Array<Symbol>] a list of fields to remove on the render_constraint_element
    # You can override this if you have different fields to remove
    def fields_to_exclude_from_constraint_element
      [:search_field]
    end

    ##
    # We can remove this method once we use Blacklight > 5.4.0
    ##
    # Return a label for the currently selected search field.
    # If no "search_field" or the default (e.g. "all_fields") is selected, then return nil
    # Otherwise grab the label of the selected search field.
    # @param [Hash] query parameters
    # @return [String]
    def constraint_query_label(localized_params = params)
      label_for_search_field(localized_params[:search_field]) unless default_search_field?(localized_params[:search_field])
    end

    ##
    # We can remove this method once we use Blacklight > 5.4.0
    ##
    # Is the search form using the default search field ("all_fields" by default)?
    # @param [String] the currently selected search_field
    # @return [Boolean]
    def default_search_field?(selected_search_field)
      selected_search_field.blank? || (default_search_field && selected_search_field == default_search_field[:key])
    end
  end
end
