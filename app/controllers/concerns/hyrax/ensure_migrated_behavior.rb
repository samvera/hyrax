# frozen_string_literal: true

module Hyrax
  ##
  # A shared module for controllers to ensure that a resource has been fully
  # migrated from a Wings-backed ActiveFedora object to a native Valkyrie resource
  # before an action (like `edit`) is performed.
  #
  # This is a temporary solution to handle just-in-time migrations for legacy
  # objects when `Hyrax.config.flexible?` is true.
  #
  # @example
  #   class MyController < ApplicationController
  #     include Hyrax::EnsureMigratedBehavior
  #
  #     before_action do
  #       @resource = find_my_resource
  #       @resource = ensure_migrated(resource: @resource, form: build_form, transaction_key: 'my.transaction')
  #     end
  #   end
  module EnsureMigratedBehavior
    extend ActiveSupport::Concern

    private

    ##
    # @param resource [Valkyrie::Resource] the resource to check
    # @param form [ChangeSet] the change set form object for the resource
    # @param transaction_key [String] the key for the update transaction
    #
    # @return [Valkyrie::Resource] the migrated resource if migration was needed,
    #   otherwise the original resource.
    def ensure_migrated(resource:, form:, transaction_key:)
      return resource unless Hyrax.config.flexible? && resource.respond_to?(:wings?) && resource.wings?

      result = transactions[transaction_key].call(form)

      raise "Valkyrie lazy migration failed for #{resource.class} #{resource.id}: #{result.failure}" unless result.success?

      result.value!
    end
  end
end
