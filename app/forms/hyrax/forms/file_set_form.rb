# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # A form for +Hyrax::FileSet+s.
    class FileSetForm < Hyrax::Forms::ResourceForm
      if Hyrax.config.file_set_include_metadata?
        include Hyrax::FormFields(:core_metadata)
        include Hyrax::FormFields(:file_set_metadata)
      end
      check_if_flexible(Hyrax::FileSet)
      include Hyrax::DepositAgreementBehavior
      include Hyrax::ContainedInWorksBehavior
      include Hyrax::LeaseabilityBehavior
      include Hyrax::PermissionBehavior

      property :representative_id, type: Valkyrie::Types::String, writeable: false
      property :thumbnail_id, type: Valkyrie::Types::String, writeable: false
    end
  end
end
