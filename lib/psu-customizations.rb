require 'active_fedora'
require 'psu/id_service'

module ActiveFedora
  class Base
    def initialize(attrs={})
      unless attrs[:pid]
        attrs = attrs.merge!({:pid => PSU::IdService.mint, :new_object => true})
      end
      super
    end  
  end
end
