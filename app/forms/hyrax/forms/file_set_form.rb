# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    class FileSetForm < Hyrax::ChangeSet
      class << self
        ##
        # @return [Array<Symbol>] list of required field names as symbols
        def required_fields
          definitions
            .select { |_, definition| definition[:required] }
            .keys.map(&:to_sym)
        end
      end

      property :title, required: true
      property :creator, required: true
      property :license, required: true

      property :based_near
      property :contributor
      property :date_created
      property :description
      property :identifier
      property :keyword
      property :language
      property :publisher
      property :related_url
      property :subject
      property :visibility, default: VisibilityIntention::PRIVATE

      # virtual properties for embargo/lease;
      property :embargo_release_date, virtual: true
      property :visibility_after_embargo, virtual: true
      property :visibility_during_embargo, virtual: true
      property :lease_expiration_date, virtual: true
      property :visibility_after_lease, virtual: true
      property :visibility_during_lease, virtual: true

      # virtual properties for pcdm membership
      property :parent, virtual: true, prepopulator: ->(_opts) { self.parent = Hyrax.query_service.find_parents(resource: model).first }

      # virtual properties for versions
      property :versions, virtual: true, prepopulator: ->(_opts) { self.versions = Hyrax::VersionListPresenter.for(file_set: model) }
    end
  end
end
