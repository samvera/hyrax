module Sufia
  module Noid
    def Noid.noidify(identifier)
      String(identifier).split(":").last
    end

    def Noid.namespaceize(identifier)
      if identifier.start_with?(Noid.namespace)
        identifier
      else
        "#{Noid.namespace}:#{identifier}"
      end
    end

    def noid
      Noid.noidify(self.pid)
    end

    def normalize_identifier
      params[:id] = Noid.namespaceize(params[:id])
    end

    protected
    def Noid.namespace
      Sufia.config.id_namespace
    end
  end
end
