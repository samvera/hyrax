# frozen_string_literals: true

module Hyrax
  class AdminSetChangeSetPersister < ChangeSetPersister
    before_delete :check_if_not_default_set
    before_delete :check_if_empty
    after_delete :destroy_permission_template

    # AdminSets have specific validations on them for delete that throw abort
    # By default ChangeSetPersisters do not handle abort,abort is handled on specific
    # persisters
    def delete(change_set:)
      catch(:abort) do
        super
      end
    end

    def check_if_empty(change_set:)
      return true if change_set.resource.members.empty?
      change_set.errors[:base] << I18n.t('hyrax.admin.admin_sets.delete.error_not_empty')
      throw :abort
    end

    def check_if_not_default_set(change_set:)
      return true unless change_set.resource.default_set?
      change_set.errors[:base] << I18n.t('hyrax.admin.admin_sets.delete.error_default_set')
      throw :abort
    end

    def destroy_permission_template(change_set:)
      change_set.resource.permission_template.destroy
    rescue ActiveRecord::RecordNotFound
      true
    end
  end
end
