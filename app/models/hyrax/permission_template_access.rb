# frozen_string_literal: true

module Hyrax
  class PermissionTemplateAccess < ActiveRecord::Base
    self.table_name = 'permission_template_accesses'

    belongs_to :permission_template

    VIEW = 'view'
    DEPOSIT = 'deposit'
    MANAGE = 'manage'

    enum(
      access: {
        VIEW => VIEW,
        DEPOSIT => DEPOSIT,
        MANAGE => MANAGE
      }
    )
  end
end
