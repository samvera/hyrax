module Sufia
  class SingleAdminSetSearchBuilder < CurationConcerns::AdminSetSearchBuilder
    include CurationConcerns::SingleResult

    def initialize(context)
      super(context, :read)
    end
  end
end
