module Sufia
  module AdminSetBehavior
    extend ActiveSupport::Concern

    included do
      DEFAULT_ID = 'admin_set/default'.freeze
      DEFAULT_WORKFLOW_NAME = 'default'.freeze

      def self.default_set?(id)
        id == DEFAULT_ID
      end

      before_destroy :check_if_not_default_set, :check_if_empty
    end

    private

      def check_if_empty
        return true if members.empty?
        errors[:base] << I18n.t('sufia.admin.admin_sets.delete.error_not_empty')
        if Rails.version < '5.0.0'
          false
        else
          throw :abort
        end
      end

      def check_if_not_default_set
        return true unless AdminSet.default_set?(id)
        errors[:base] << I18n.t('sufia.admin.admin_sets.delete.error_default_set')
        if Rails.version < '5.0.0'
          false
        else
          throw :abort
        end
      end
  end
end
