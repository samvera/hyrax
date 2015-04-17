module Hydra::ContentNegotiation
  # Finds a graph given a connection and ID.
  class GraphFinder
    attr_reader :connection, :id
    def initialize(connection, id)
      @connection = connection
      @id = id
    end

    def graph
      connection.get(uri).graph
    end

    def uri
      ActiveFedora::Base.id_to_uri(id)
    end
  end
end
