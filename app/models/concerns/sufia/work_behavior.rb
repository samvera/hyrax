module Sufia
  module WorkBehavior
    extend ActiveSupport::Concern
    include Sufia::ProxyDeposit
    include Sufia::Works::Trophies
    include Sufia::Works::Metadata
    include Sufia::WithEvents

    included do
      self.indexer = Sufia::WorkIndexer
    end
  end
end
