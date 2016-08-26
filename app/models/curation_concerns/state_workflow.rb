module CurationConcerns
  class StateWorkflow
    # @param [String, RDF::Term] state a represesentation of the workflow
    def initialize(state)
      @state = state.respond_to?(:to_sym) ? state.to_sym : state
    end
    attr_reader :state

    def pending?
      state == :pending
    end
  end
end
