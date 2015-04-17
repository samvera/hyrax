module Hydra::ContentNegotiation
  # CleanGraphRepository has a #find interface which returns a graph for use
  # with content negotiation.
  class CleanGraphRepository
    attr_reader :connection
    def initialize(connection)
      @connection = connection
    end

    def find(id)
      ReplacingGraphFinder.new(
        GraphFinder.new(connection, id)
      ).graph
    end
  end
end
