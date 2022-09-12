# frozen_string_literal: true
module Hyrax
  require 'active_fedora/errors'

  # Generic Hyrax exception class.
  class HyraxError < StandardError; end

  # Error that is raised when an active workflow can't be found
  class MissingWorkflowError < HyraxError; end

  class WorkflowAuthorizationException < HyraxError; end

  class SingleUseError < HyraxError; end

  class SingleMembershipError < HyraxError; end

  class ObjectNotFoundError < ActiveFedora::ObjectNotFoundError; end

  class ModelMismatchError < HyraxError; end
end
