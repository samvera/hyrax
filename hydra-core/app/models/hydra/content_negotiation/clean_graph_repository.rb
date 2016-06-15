module Hydra::ContentNegotiation
  # CleanGraphRepository has a #find interface which returns a graph for use
  # with content negotiation.
  class CleanGraphRepository
    attr_reader :connection, :replacer
    # @param [#get] connection the connection to fedora
    # @param [#call] replacer a function that is called with id and graph and returns a string representation of the new uri.
    def initialize(connection, replacer = Hydra.config.id_to_resource_uri)
      @connection = connection
      @replacer = replacer
    end

    def find(id)
      ReplacingGraphFinder.new(
        GraphFinder.new(connection, id),
        replacer
      ).graph
    end
  end
end
