module Sufia
  module Noid

    def noid
      Noid.noidify(self.pid)
    end

    # Redefine this for more intuitive keys in Redis
    def to_param
      noid
    end

    class << self
      def noidify(identifier)
        String(identifier).split(":").last
      end

      def namespaceize(identifier)
        if identifier.start_with?(namespace)
          identifier
        else
          "#{namespace}:#{identifier}"
        end
      end

      protected

      def namespace
        Sufia.config.id_namespace
      end
    end
  end
end
