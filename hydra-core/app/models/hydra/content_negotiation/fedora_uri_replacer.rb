module Hydra::ContentNegotiation
  # Replaces Fedora URIs in a graph with a Hydra-configured alternative.
  class FedoraUriReplacer
    def initialize(fedora_base_uri, graph)
      @fedora_base_uri = fedora_base_uri
      @graph = graph
    end

    def run
      RDF::Graph.new.insert(*replaced_objects)
    end

    private

    attr_reader :fedora_base_uri, :graph

    def replace_uri(uri)
      id = ActiveFedora::Base.uri_to_id(uri)
      RDF::URI(Hydra.config.id_to_resource_uri.call(id))
    end

    def replaced_objects
      replaced_subjects.map do |statement|
        if fedora_uri?(statement.object)
          RDF::Statement.from([statement.subject, statement.predicate, replace_uri(statement.object)])
        else
          statement
        end
      end
    end

    def fedora_uri?(subject)
      subject.to_s.start_with?(fedora_base_uri.to_s)
    end

    def replaced_subjects
      graph.each_statement.to_a.map do |s|
        if fedora_uri?(s.subject)
          RDF::Statement.from([replace_uri(s.subject), s.predicate, s.object])
        else
          s
        end
      end
    end
  end
end
