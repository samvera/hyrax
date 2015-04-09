module Hydra::ContentNegotiation
  # Decorator for Finder which replaces Fedora subjects in the graph with a 
  # configured URI
  class ReplacingGraphFinder < SimpleDelegator
    def graph
      graph_replacer.run
    end

    private

    def graph_replacer
      ::Hydra::ContentNegotiation::FedoraUriReplacer.new(base_uri, __getobj__.graph)
    end

    def base_uri
      @base_uri ||= uri.gsub(/#{id}$/,'')
    end
  end
end
