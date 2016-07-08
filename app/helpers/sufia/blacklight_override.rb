module Sufia
  module BlacklightOverride
    # This overrides curation_concerns so we aren't removing any fields.
    # @return [Array<Symbol>] a list of fields to remove on the render_constraint_element
    # You can override this if you have different fields to remove
    def fields_to_exclude_from_constraint_element
      []
    end
  end
end
