module CurationConcerns
  module RenderConstraintsHelper
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
  end
end
