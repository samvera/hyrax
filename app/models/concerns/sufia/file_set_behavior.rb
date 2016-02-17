module Sufia
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Sufia::WithEvents
    include Sufia::ProxyDeposit
  end
end
