# frozen_string_literal: true

require_dependency 'hyrax/resource_name'

module Hyrax
  ##
  # The base Valkyrie model for Hyrax.
  #
  # @note Hyrax permissions are managed via
  #   [Access Control List](https://en.wikipedia.org/wiki/Access-control_list)
  #   style permissions. Legacy Hyrax models powered by `ActiveFedora` linked
  #   the ACLs from the repository object itself (as an `acl:accessControl` link
  #   to a container). Valkyrie models jettison that approach in favor of relying
  #   on links back from the permissions using `access_to`. As was the case in
  #   the past implementation, we include an object to represent the access list
  #   itself (`Hyrax::AccessControl`). This object's `#access_to` is the way
  #   Hyrax discovers list entries--it MUST match between the `AccessControl`
  #   and its individual `Permissions`.
  #
  #   The effect of this change is that our `AccessControl` objects are detached
  #   from `Hyrax::Resource` they can (and usually should) be edited and
  #   persisted independently from the resource itself.
  #
  #   Some utilitiy methods are provided for ergonomics in transitioning from
  #   `ActiveFedora`: the `#visibility` accessor, and the `#*_users` and
  #   `#*_group` accessors. The main purpose of these is to provide a cached
  #   ACL attached to a given Resource instance. However, these will likely be
  #   deprecated in the future, and it's advisable to avoid them in favor of
  #   `Hyrax::AccessControlList`, `Hyrax::PermissionManager` and/or
  #   `Hyrax::VisibilityWriter` (which provide their underlying
  #   implementations).
  #
  class Resource < Valkyrie::Resource
    include Hyrax::Naming
    include Hyrax::WithEvents

    attribute :alternate_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID)
    attribute :embargo,       Hyrax::Embargo.optional
    attribute :lease,         Hyrax::Lease.optional

    delegate :edit_groups, :edit_groups=,
             :edit_users,  :edit_users=,
             :read_groups, :read_groups=,
             :read_users,  :read_users=, to: :permission_manager

    class << self
      ##
      # @return [String] a human readable name for the model
      def human_readable_type
        I18n.translate("hyrax.models.#{model_name.i18n_key}", default: model_name.human)
      end

      private

      ##
      # @api private
      #
      # @return [Class] an ActiveModel::Name compatible class
      def _hyrax_default_name_class
        Hyrax::ResourceName
      end
    end

    ##
    # @return [Boolean]
    def collection?
      false
    end

    ##
    # @return [Boolean]
    def file?
      false
    end

    ##
    # @return [Boolean]
    def file_set?
      false
    end

    ##
    # @return [Boolean]
    def pcdm_object?
      false
    end

    ##
    # @return [Boolean]
    def work?
      false
    end

    def permission_manager
      @permission_manager ||= Hyrax::PermissionManager.new(resource: self)
    end

    def visibility=(value)
      visibility_writer.assign_access_for(visibility: value)
    end

    def visibility
      visibility_reader.read
    end

    protected

    def visibility_writer
      Hyrax::VisibilityWriter.new(resource: self)
    end

    def visibility_reader
      Hyrax::VisibilityReader.new(resource: self)
    end
  end
end
