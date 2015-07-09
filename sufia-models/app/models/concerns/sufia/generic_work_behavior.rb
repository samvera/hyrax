module Sufia
  module GenericWorkBehavior
    extend ActiveSupport::Concern
    include Sufia::ProxyDeposit

    # TODO: remove?
    def collection?
      false
    end

  end
end
