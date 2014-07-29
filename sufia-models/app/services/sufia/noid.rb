module Sufia
  module Noid
    extend ActiveSupport::Concern

    module ClassMethods
      ## This overrides the default behavior, which is to ask Fedora for a pid
      # @see ActiveFedora::Sharding.assign_pid
      def assign_pid(_)
        Sufia::IdService.mint
      end
    end

    def noid
      Noid.noidify(id)
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
