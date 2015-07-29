module Hydra
  module ContentNegotiation
    def self.extended(document)
      document.will_export_as(:nt, "application/n-triples")
      document.will_export_as(:jsonld, "application/ld+json")
      document.will_export_as(:ttl, "text/turtle")
    end

    def export_as_nt
      clean_graph.dump(:ntriples)
    end

    def export_as_jsonld
      clean_graph.dump(:jsonld, :standard_prefixes => true)
    end

    def export_as_ttl
      clean_graph.dump(:ttl)
    end

    private

    def clean_graph
      @clean_graph ||= clean_graph_repository.find(id)
    end

    def clean_graph_repository
      CleanGraphRepository.new(connection)
    end

    def connection
      ActiveFedora.fedora.clean_connection
    end
  end
end
