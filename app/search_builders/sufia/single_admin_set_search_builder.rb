module Sufia
  class SingleAdminSetSearchBuilder < Sufia::AdminSetSearchBuilder
    include Sufia::SingleResult

    def initialize(context)
      super(context, :read)
    end
  end
end
