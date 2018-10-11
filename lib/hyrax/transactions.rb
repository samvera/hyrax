# frozen_string_literal: true
require 'hyrax/transactions/container'

module Hyrax
  ##
  # This is a parent module for DRY Transaction classes handling Hyrax
  # processes. Especially: transactions and steps for creating, updating, and
  # destroying PCDM Objects are located here. Loading this module provides an
  # easy way to load the full suite of transactions included for these purposes.
  #
  # @note These uses of `dry-transaction` are currently experimental
  #   replacements for actor stack behavior. They are not loaded during normal
  #   execution in a stock Hyrax application.
  #
  # @since 2.4.0
  #
  # @example
  #   require 'hyrax/transactions'
  #
  # @see https://dry-rb.org/gems/dry-transaction/
  module Transactions
  end
end
