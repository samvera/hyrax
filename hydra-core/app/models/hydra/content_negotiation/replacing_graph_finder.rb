module Hydra::ContentNegotiation
  # Decorator for Finder which replaces Fedora subjects in the graph with a 
  # configured URI
  class ReplacingGraphFinder < SimpleDelegator

    attr_reader :replacer
    def initialize(graph_finder, replacer)
      super(graph_finder)
      @replacer = replacer
    end

    def graph
      graph_replacer.run
    end

    private

    def graph_replacer
      ::Hydra::ContentNegotiation::FedoraUriReplacer.new(base_uri,
                                                         __getobj__.graph,
                                                         replacer)
    end

    def base_uri
      @base_uri ||= ActiveFedora.fedora.host + ActiveFedora.fedora.base_path
    end
  end
end
