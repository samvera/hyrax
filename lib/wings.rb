# The isolating namespace for integrating Valkyrie into Hyrax as a bridge away
# from the hard dependency on ActiveFedora.
#
# @see https://wiki.duraspace.org/display/samvera/Hyrax-Valkyrie+Development+Working+Group
#      for further context regarding the approach
module Wings
end

require 'valkyrie'
require 'wings/model_transformer'
require 'wings/resource_factory'
require 'wings/valkyrizable'
require 'wings/valkyrie_monkey_patch'

ActiveFedora::Base.include Wings::Valkyrizable
