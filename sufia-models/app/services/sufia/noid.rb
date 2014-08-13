module Sufia
  module Noid
    extend ActiveSupport::Concern

    ## This overrides the default behavior, which is to ask Fedora for a pid
    # @see ActiveFedora::Sharding.assign_pid
    def assign_pid
      Sufia::IdService.mint
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

      # Create a pairtree like path for the given identifier
      def treeify(identifier)
        (identifier.scan(/..?/).first(4) + [identifier]).join('/')
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
