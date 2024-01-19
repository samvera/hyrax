# frozen_string_literal: true
module Hyrax
  ##
  # A module of form behaviours for depositors and depositor agreements.
  module DepositAgreementBehavior
    def self.included(descendant)
      descendant.property :depositor

      descendant.property :agreement_accepted, virtual: true, default: false, prepopulator: proc { |_opts| self.agreement_accepted = !model.new_record }
    end
  end
end
