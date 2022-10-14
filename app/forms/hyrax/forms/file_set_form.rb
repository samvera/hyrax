# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    class FileSetForm < Hyrax::ChangeSet
      include Hyrax::FormFields(:core_metadata)

      # The fields in +:file_set_metadata+ were hardcoded into this form in a
      # previous version of Hyrax, but ideally in the future this metadata will
      # be configurable.
      include Hyrax::FormFields(:file_set_metadata)

      class << self
        ##
        # @return [Array<Symbol>] list of required field names as symbols
        def required_fields
          definitions
            .select { |_, definition| definition[:required] }
            .keys.map(&:to_sym)
        end
      end

      property :permissions, virtual: true
      property :visibility, default: VisibilityIntention::PRIVATE

      # virtual properties for embargo/lease;
      property :embargo_release_date, virtual: true
      property :visibility_after_embargo, virtual: true
      property :visibility_during_embargo, virtual: true
      property :lease_expiration_date, virtual: true
      property :visibility_after_lease, virtual: true
      property :visibility_during_lease, virtual: true
    end
  end
end
