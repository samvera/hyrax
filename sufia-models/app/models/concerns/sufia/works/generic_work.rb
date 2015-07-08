# a very simple type of work with DC metadata
module Sufia::Works
  module GenericWork
    extend ActiveSupport::Concern

    include Sufia::Works::GenericWork::ProxyDeposit
  end
end
