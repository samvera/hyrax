# frozen_string_literal: true
module Hyrax
  module Transactions
    class CreateWork
      include Dry::Transaction(container: Hyrax::Transactions::Container)

      step :set_default_admin_set,      with: 'work.set_default_admin_set'
      step :ensure_admin_set,           with: 'work.ensure_admin_set'
      step :ensure_permission_template, with: 'work.ensure_permission_template'
      step :set_modified_date,          with: 'work.set_modified_date'
      step :set_uploaded_date,          with: 'work.set_uploaded_date'
      step :save_work,                  with: 'work.save_work'
    end
  end
end
