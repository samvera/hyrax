require 'active_fedora'
require 'psu/id_service'

module ActiveFedora
  class Base
    def initialize(attrs={})
      unless attrs[:pid]
        attrs = attrs.merge!({:pid => PSU::IdService.mint})
        @new_object = true
      else
        @new_object = not attrs[:new_object] == false
      end
      @inner_object = Fedora::FedoraObject.new(attrs)
      @datastreams = {}
      configure_defined_datastreams
    end  
  end
end
