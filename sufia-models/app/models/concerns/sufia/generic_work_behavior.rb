module Sufia
  module GenericWorkBehavior
    extend ActiveSupport::Concern
    include Sufia::ProxyDeposit
    include Sufia::Works::Trophies

    # TODO: remove?
    def collection?
      false
    end

  end
end
