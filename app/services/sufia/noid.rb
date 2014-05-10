# No overrides here.  Purely addressing an autoload bug.
module Sufia
  module Noid
    def self.noidify(identifier)
      String(identifier).split(":").last
    end

    def self.namespaceize(identifier)
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
    def self.namespace
      Sufia.config.id_namespace
    end
  end
end
