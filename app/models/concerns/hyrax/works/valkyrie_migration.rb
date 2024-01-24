# frozen_string_literal: true

module Hyrax
  module Works
    ##
    # This mixin is for {Valkyrie::Resource} objects to be able to read/write the same Solr document
    # as their corresponding {ActiveFedora::Base} object.
    #
    # This module assumes that for GenericWorkResource that there is a corresponding GenericWork
    # class; Something that is useful as applications look to migrate in place from an
    # ActiveFedora::Base GenericWork representation to a Valkyrie based GenericWorkResource.
    #
    # Put another way, this is convention over configuration for enabling us to re-use logic around
    # solr documents.
    #
    # @see https://github.com/samvera/hyrax/pull/6221 Discussion about having one indexed document
    module ValkyrieMigration
      extend ActiveSupport::Concern

      included do
        attribute :internal_resource, Valkyrie::Types::Any.default(to_rdf_representation.freeze), internal: true
      end

      class_methods do
        def _hyrax_default_name_class
          Hyrax::Name
        end

        def to_rdf_representation
          name.gsub("Resource", "")
        end
      end

      def members
        return @members if @members.present?
        @members = member_ids.map do |id|
          Hyrax.query_service.find_by(id: id)
        rescue Valkyrie::Persistence::ObjectNotFoundError
          Rails.logger.warn("Could not find member #{id} for #{self.id}")
        end
      end

      def to_solr
        Hyrax::ValkyrieIndexer.for(resource: self).to_solr
      end
    end
  end
end
