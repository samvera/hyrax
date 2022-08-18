# frozen_string_literal: true
module Hyrax
  module Forms
    ##
    # Nested form for leases.
    class Lease < Hyrax::ChangeSet
      property :visibility_after_lease
      property :visibility_during_lease
      property :lease_expiration_date
      property :lease_history, default: []
    end
  end
end
