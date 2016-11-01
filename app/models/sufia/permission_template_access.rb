# frozen_string_literal: true
module Sufia
  class PermissionTemplateAccess < ActiveRecord::Base
    belongs_to :permission_template

    def view?
      access == 'view'
    end

    def deposit?
      access == 'deposit'
    end

    def manage?
      access == 'manage'
    end
  end
end
