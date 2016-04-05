module Sufia
  module BlacklightOverride
    # TODO: we can remove this override when we can depend on https://github.com/projecthydra-labs/curation_concerns/pull/711
    def render_constraints_query(localized_params = params)
      # So simple don't need a view template, we can just do it here.
      return "".html_safe if localized_params[:q].blank?

      render_constraint_element(constraint_query_label(localized_params),
                                localized_params[:q],
                                classes: ["query"],
                                remove: remove_constraint_url(localized_params))
    end

    # TODO: we can remove this override when we can depend on https://github.com/projecthydra-labs/curation_concerns/pull/711
    def remove_constraint_url(localized_params)
      scope = localized_params.delete(:route_set) || self
      options = localized_params.merge(q: nil, action: 'index')
                                .except(*fields_to_exclude_from_constraint_element)
      options.permit!
      scope.url_for(options)
    end

    # This overrides curation_concerns so we aren't removing any fields.
    # @return [Array<Symbol>] a list of fields to remove on the render_constraint_element
    # You can override this if you have different fields to remove
    def fields_to_exclude_from_constraint_element
      []
    end
  end
end
