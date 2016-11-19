module Sufia
  class SingleAdminSetSearchBuilder < Sufia::AdminSetSearchBuilder
    include CurationConcerns::SingleResult

    def initialize(context)
      super(context, :read)
    end
  end
end
