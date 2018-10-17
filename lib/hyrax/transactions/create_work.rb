# frozen_string_literal: true
module Hyrax
  module Transactions
    ##
    # A transaction for creating a Work ready for use in Hyrax. Handles
    # ensuring admin sets and permission templates are present, and setting
    # system managed dates prior to save.
    #
    # @note This is an experimental replacement for the actor stack's `#create`
    #   stack. In time, we hope this will have feature parity with that stack,
    #   along with improved architecture, error handling, readability, and
    #   customizability. While this develops, please provide feedback.
    #
    # @since 2.4.0
    #
    # @example Creating a work transactionally
    #   work   = MyWork.new(title: ['Comet in Moominland'])
    #   result = Hyrax::Transactions::CreateWork.call(work)
    #   result.success? => true
    #
    # @example Handling errors with procedural style
    #   work   = MyWork.new # invalid work (no title)
    #   result = Hyrax::Transactions::CreateWork.call(work)
    #   result.success? => false
    #
    #   result.failure # => failure description or object
    #
    # @example Handling errors with `#or`
    #   work   = MyWork.new # invalid work (no title)
    #
    #   Hyrax::Transactions::CreateWork
    #     .call(work)
    #     .or { |error| handle_error(error) }
    #
    # @see https://dry-rb.org/gems/dry-transaction/
    class CreateWork
      include Dry::Transaction(container: Hyrax::Transactions::Container)

      step :set_default_admin_set,     with: 'work.set_default_admin_set'
      step :ensure_admin_set,          with: 'work.ensure_admin_set'
      step :apply_permission_template, with: 'work.apply_permission_template'
      step :set_modified_date,         with: 'work.set_modified_date'
      step :set_uploaded_date,         with: 'work.set_uploaded_date'
      step :save_work,                 with: 'work.save_work'
    end
  end
end
