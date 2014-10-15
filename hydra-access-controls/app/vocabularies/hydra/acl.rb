module Hydra
  class ACL < RDF::StrictVocabulary('http://projecthydra.org/ns/auth/acl#')
    property :Discover # extends http://www.w3.org/ns/auth/acl#Access

    property :hasEmbargo
    property :hasLease

    property :visibility_during_embargo
    property :visibility_after_embargo
    property :embargo_release_date
    property :visibility_during_lease
    property :visibility_after_lease
    property :lease_expiration_date

    property :embargo_history
    property :lease_history

    property :defaultPermissions
  end
end
