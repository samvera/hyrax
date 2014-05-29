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
        return identifier if identifier.include?(':')
        "#{namespace}:#{identifier}"
      end

      protected

      def namespace
        Sufia.config.id_namespace
      end
    end
  end
end
