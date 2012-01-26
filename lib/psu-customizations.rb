require 'active_fedora'
require 'psu/id_service'

module ActiveFedora
  class UnsavedDigitalObject 
    def assign_pid
      return @pid if @pid
      @pid = PSU::IdService.mint
      @pid
    end
  end
end
