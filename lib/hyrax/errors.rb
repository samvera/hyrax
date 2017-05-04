module Hyrax
  # Generic Hyrax exception class.
  class HyraxError < StandardError; end

  # Error that is raised when an active workflow can't be found
  class MissingWorkflowError < HyraxError; end

  class WorkflowAuthorizationException < HyraxError; end

  class SingleUseError < HyraxError; end
end
