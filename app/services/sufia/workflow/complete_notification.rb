module Sufia
  module Workflow
    class CompleteNotification < DepositedNotification
      deprecation_deprecate initialize: "use DepositedNotification.initialize instead"
    end
  end
end
