module Hyrax
  class SingleAdminSetSearchBuilder < Hyrax::AdminSetSearchBuilder
    include Hyrax::SingleResult

    def initialize(context)
      super(context, :read)
    end
  end
end
