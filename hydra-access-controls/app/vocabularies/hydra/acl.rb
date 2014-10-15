module Hydra
  class ACL < RDF::StrictVocabulary('http://projecthydra.org/ns/auth/acl#')
    property :Discover # extends http://www.w3.org/ns/auth/acl#Access

    property :hasEmbargo
    property :hasLease

    property :visibilityDuringEmbargo
    property :visibilityAfterEmbargo
    property :embargoReleaseDate
    property :visibilityDuringLease
    property :visibilityAfterLease
    property :leaseExpirationDate

    property :embargoHistory
    property :leaseHistory

    property :defaultPermissions
  end
end
