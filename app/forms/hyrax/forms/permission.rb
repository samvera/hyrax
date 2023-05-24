# frozen_string_literal: true
module Hyrax
  module Forms
    ##
    # Nested form for permissions.
    #
    # @note due to historical oddities with Hydra::AccessControls and Hydra
    #   Editor, Hyrax's views rely on `agent_name` and `access` as field
    #   names. we provide these as virtual fields and prepopulate these from
    #   `Hyrax::Permission`.
    class Permission < Hyrax::ChangeSet
      property :agent_name, virtual: true, prepopulator: proc { |_opts| self.agent_name = model.agent }
      property :access, virtual: true, prepopulator: proc { |_opts| self.access = model.mode }

      ##
      # @note support a {#to_hash} method for compatibility with
      #   {Hydra::AccessControl::Permissions}
      def to_hash
        { name: agent_name, access: access }
      end
    end
  end
end
