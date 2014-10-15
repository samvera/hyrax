module Hydra::AccessControls
  class Lease < ActiveFedora::Base
    # TODO change names
    property :visibility_during_lease, predicate: Hydra::ACL.visibility_during_lease
    property :visibility_after_lease, predicate: Hydra::ACL.visibility_after_lease
    property :lease_expiration_date, predicate: Hydra::ACL.lease_expiration_date

    property :lease_history, predicate: Hydra::ACL.lease_history

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def visibility_during_lease_with_first
      visibility_during_lease_without_first.first
    end
    alias_method_chain :visibility_during_lease, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def visibility_after_lease_with_first
      visibility_after_lease_without_first.first
    end
    alias_method_chain :visibility_after_lease, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def lease_expiration_date_with_first
      lease_expiration_date_without_first.first
    end
    alias_method_chain :lease_expiration_date, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def lease_expiration_date_with_casting=(date)
      date = DateTime.parse(date) if date && date.kind_of?(String)
      self.lease_expiration_date_without_casting = date
    end
    alias_method_chain :lease_expiration_date=, :casting

  end
end
