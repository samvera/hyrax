module Sufia
  module WorkBehavior
    extend ActiveSupport::Concern
    include Sufia::ProxyDeposit
    include Sufia::Works::Trophies
  end
end
