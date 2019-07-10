# frozen_string_literal: true

module Hyrax
  ##
  # The base Valkyrie model for Hyrax.
  class Resource < Valkyrie::Resource
    include Valkyrie::Resource::AccessControls

    attribute :alternate_ids, ::Valkyrie::Types::Array
    attribute :embargo,       Hyrax::Embargo
    attribute :lease,         Hyrax::Lease

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
