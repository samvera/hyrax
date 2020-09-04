module Hyrax
  module WorkflowsHelper
    # Does a workflow restriction exist for the given :object and
    # given :ability?
    #
    # @note If the object responds to a :workflow_restriction?, we'll
    #       use that answer.
    #
    # This method doesn't answer what kind of restriction is in place
    # (that requires a far more nuanced permissioning system than
    # Hyrax presently has).  Instead, it answers is there one in
    # place.  From that answer, you may opt out of rendering a region
    # on a view (e.g. don't show links to the edit page).
    #
    # @param object [Object]
    # @param ability [Ability]
    #
    # @return [false] when there are no applicable workflow restrictions
    #
    # @return [true] when there is an applicable workflow restriction,
    #         and you likely want to not render something.
    #
    # @note This is Jeremy, I encourage you to look at the views that
    #       call this method to understand the conceptual space this
    #       method covers.
    def workflow_restriction?(object, with_ability: current_ability)
      return object.workflow_restriction? if object.respond_to?(:workflow_restriction?)
      return false
    end
  end
end
