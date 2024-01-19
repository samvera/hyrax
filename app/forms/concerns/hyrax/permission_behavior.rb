# frozen_string_literal: true
module Hyrax
  ##
  # A module of form behaviours for populating permissions.
  module PermissionBehavior
    def self.included(descendant)
      descendant.collection(:permissions,
                 virtual: true,
                 default: [],
                 form: Hyrax::Forms::Permission,
                 populator: :permission_populator,
                 prepopulator: proc { |_opts| self.permissions = Hyrax::AccessControl.for(resource: model).permissions })
    end

    # https://trailblazer.to/2.1/docs/reform.html#reform-populators-populator-collections
    def permission_populator(collection:, index:, **)
      Hyrax::Forms::Permission.new(collection[index])
    end
  end
end
