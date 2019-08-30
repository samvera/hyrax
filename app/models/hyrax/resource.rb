# frozen_string_literal: true

module Hyrax
  ##
  # The base Valkyrie model for Hyrax.
  class Resource < Valkyrie::Resource
    attribute :alternate_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID)
    attribute :embargo,       Hyrax::Embargo.optional
    attribute :lease,         Hyrax::Lease.optional

    delegate :edit_groups, :edit_groups=,
             :edit_users,  :edit_users=,
             :read_groups, :read_groups=,
             :read_users,  :read_users=, to: :permission_manager

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
