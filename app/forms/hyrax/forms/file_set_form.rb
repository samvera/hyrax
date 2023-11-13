# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # A form for +Hyrax::FileSet+s.
    class FileSetForm < Hyrax::Forms::ResourceForm
      include Hyrax::FormFields(:core_metadata)

      # The fields in +:file_set_metadata+ were hardcoded into this form in a
      # previous version of Hyrax, but ideally in the future this metadata will
      # be configurable.
      include Hyrax::FormFields(:file_set_metadata)

      include Hyrax::DepositAgreementBehavior
      include Hyrax::ContainedInWorksBehavior
      include Hyrax::LeaseabilityBehavior
      include Hyrax::PermissionBehavior

      property :representative_id, type: Valkyrie::Types::String, writeable: false
      property :thumbnail_id, type: Valkyrie::Types::String, writeable: false
    end
  end
end
