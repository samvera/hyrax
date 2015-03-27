module Sufia
  module Noid
    extend ActiveSupport::Concern

    ## This overrides the default behavior, which is to ask Fedora for an id
    # @see ActiveFedora::Persistence.assign_id
    def assign_id
      Sufia::IdService.mint if Sufia.config.enable_noids
    end

    def to_param
      id
    end

    class << self
      # Create a pairtree like path for the given identifier
      def treeify(identifier)
        (identifier.scan(/..?/).first(4) + [identifier]).join('/')
      end
    end
  end
end
