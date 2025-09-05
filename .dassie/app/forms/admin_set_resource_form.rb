# frozen_string_literal: true

class AdminSetResourceForm < Hyrax::Forms::AdministrativeSetForm
  include Hyrax::FormFields(:basic_metadata) if Hyrax.config.admin_set_include_metadata?
  check_if_flexible(AdminSetResource)
end
