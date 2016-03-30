module Sufia
  module WorkBehavior
    extend ActiveSupport::Concern
    include Sufia::ProxyDeposit
    include Sufia::Works::Trophies
    include Sufia::Works::Metadata
    include Sufia::Works::Querying
    include Sufia::WithEvents
    include Sufia::BelongsToUploadSets
    # TODO: remove once https://github.com/projecthydra-labs/curation_concerns/pull/702
    # is merged and released
    include GlobalID::Identification
  end
end
