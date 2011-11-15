module Hydra::GenericContentObjectsHelperBehavior
  
  def datastream_disseminator_url pid, datastream_name
    begin
      base_url = Fedora::Repository.instance.send(:connection).site.to_s
    rescue
      base_url = "http://localhost:8983/fedora"
    end
    "#{base_url}/get/#{pid}/#{datastream_name}"
  end
  
  def disseminator_link pid, datastream_name
    link_to 'view', datastream_disseminator_url(pid, datastream_name), :class=>"fbImage"
  end
  
end
