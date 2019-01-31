# The isolating namespace for integrating Valkyrie into Hyrax as a bridge away
# from the hard dependency on ActiveFedora.
#
# @see https://wiki.duraspace.org/display/samvera/Hyrax-Valkyrie+Development+Working+Group
#      for further context regarding the approach
module Wings
end

require 'valkyrie'
require 'wings/resource_factory'
require 'wings/metadata_adapter'
require 'wings/valkyrizable'
require 'wings/valkyrie_monkey_patch'

ActiveFedora::Base.include Wings::Valkyrizable

Valkyrie::MetadataAdapter.register(
  Valkyrie::Persistence::ActiveFedora::MetadataAdapter.new,
  :wings_adapter

)

Valkyrie::StorageAdapter.register(
  Valkyrie::Storage::Fedora.new(connection: Ldp::Client.new(ActiveFedora.fedora.host)),
  :fedora
)
