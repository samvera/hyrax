module Hydra::GenericContentObjectsHelperBehavior
  
  def datastream_disseminator_url pid, datastream_name
    ActiveFedora::Base.connection_for_pid(pid).client.url + "/get/#{pid}/#{datastream_name}"
  end
  
  def disseminator_link pid, datastream_name
    link_to 'view', datastream_disseminator_url(pid, datastream_name), :class=>"fbImage"
  end
  
end
