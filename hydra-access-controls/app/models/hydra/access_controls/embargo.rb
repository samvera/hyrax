module Hydra::AccessControls
  class Embargo < ActiveFedora::Base
    # TODO change names
    property :visibility_during_embargo, predicate: Hydra::ACL.visibility_during_embargo
    property :visibility_after_embargo, predicate: Hydra::ACL.visibility_after_embargo
    property :embargo_release_date, predicate: Hydra::ACL.embargo_release_date
    property :embargo_history, predicate: Hydra::ACL.embargo_history

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def visibility_during_embargo_with_first
      visibility_during_embargo_without_first.first
    end
    alias_method_chain :visibility_during_embargo, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def visibility_after_embargo_with_first
      visibility_after_embargo_without_first.first
    end
    alias_method_chain :visibility_after_embargo, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def embargo_release_date_with_first
      embargo_release_date_without_first.first
    end
    alias_method_chain :embargo_release_date, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def embargo_release_date_with_casting=(date)
      date = DateTime.parse(date) if date && date.kind_of?(String)
      self.embargo_release_date_without_casting = date
    end
    alias_method_chain :embargo_release_date=, :casting

  end
end
