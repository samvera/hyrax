# a very simple type of work with DC metadata
module Sufia::Works
  module GenericWork
    extend ActiveSupport::Concern
    include Hydra::Works::GenericWorkBehavior
    include Sufia::Works::Work
    include Sufia::Works::CurationConcern::WithBasicMetadata
    include Sufia::Works::GenericWork::Metadata
    # TODO: Remove these items once the collection size(#1120) and 
    # processing tickets(#1122) are closed.
    include Sufia::GenericFile::Batches
    include Sufia::GenericFile::Content
    include Sufia::GenericFile::Permissions
    include Sufia::Works::GenericWork::ProxyDeposit
  end
end
