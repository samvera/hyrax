module CurationConcerns
  module RenderConstraintsHelper
    # Overridden to remove the 'search_field' tag from the localized params when the query is cleared.
    # This is because unlike Blacklight, there is no way to change the search_field in the curation_concerns UI
    ##
    # Render the query constraints
    #
    # @param [Hash] query parameters
    # @return [String]
    def render_constraints_query(localized_params = params)
      # So simple don't need a view template, we can just do it here.
      return ''.html_safe if localized_params[:q].blank?

      render_constraint_element(constraint_query_label(localized_params),
                                localized_params[:q],
                                classes: ['query'],
                                remove: url_for(localized_params.except(:search_field).merge(q: nil, action: 'index')))
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
