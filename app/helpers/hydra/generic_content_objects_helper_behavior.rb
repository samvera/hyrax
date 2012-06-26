require 'deprecation'
module Hydra::GenericContentObjectsHelperBehavior
  extend Deprecation
    
  self.deprecation_horizon = 'hydra-head 5.x'
  
  def datastream_disseminator_url pid, datastream_name
    ActiveFedora::Base.connection_for_pid(pid).client.url + "/get/#{pid}/#{datastream_name}"
  end
  #deprecation_deprecate :datastream_disseminator_url
  
  def disseminator_link pid, datastream_name
    link_to 'view', datastream_disseminator_url(pid, datastream_name), :class=>"fbImage"
  end
  #deprecation_deprecate :disseminator_link
  
end
